import AppKit
import Foundation
import SwiftUI

struct UsageWindow: Codable {
    let label: String
    let usedMinutes: Int
    let limitMinutes: Int
    let remainingMinutes: Int
    let usedPercentage: Double
    let resetsAt: String
}

struct PaceSnapshot: Codable {
    let status: String
    let summary: String
    let detail: String
}

struct HistorySnapshot: Codable {
    let capturedAt: String
    let weeklyUsedMinutes: Int
    let rollingUsedMinutes: Int
    let note: String
}

struct AccountSnapshot: Codable {
    let accountId: String
    let label: String
    let email: String
    let workspaceLabel: String
    let plan: String
    let color: String
    let source: String
    let lastSyncedAt: String
    let weeklyWindow: UsageWindow
    let rollingWindow: UsageWindow
    let pace: PaceSnapshot
    let history: [HistorySnapshot]
}

struct AccountConfig: Codable, Identifiable {
    let id: String
    let label: String
    let email: String
    let workspaceLabel: String
    let plan: String
    let color: String
    let chatGPTCookie: String
    let source: String?
    let sessionEndpoint: String?
    let usageEndpoint: String?
    let accountHeader: String?
}

struct PulseConfig: Codable {
    let localCacheEndpoint: String
    let pollIntervalSeconds: Double
    let accounts: [AccountConfig]
}

enum PulseError: Error, LocalizedError {
    case missingConfig(URL)
    case invalidSessionToken
    case invalidUsageResponse

    var errorDescription: String? {
        switch self {
        case .missingConfig(let url):
            return "Missing config at \(url.path(percentEncoded: false))"
        case .invalidSessionToken:
            return "ChatGPT session cookie did not yield an access token."
        case .invalidUsageResponse:
            return "Usage endpoint did not contain enough fields to normalize."
        }
    }
}

@MainActor
final class PulseCoordinator: ObservableObject {
    @Published var statusLine = "Idle"
    @Published var lastSyncedAt: String?
    @Published var accountCount = 0

    private let decoder = JSONDecoder()
    private var timer: Timer?
    private var hasStarted = false

    func start() {
        guard !hasStarted else {
            return
        }

        hasStarted = true
        Task {
            await syncNow()
            scheduleNextSync()
        }
    }

    func syncNow() async {
        do {
            let config = try loadConfig()
            accountCount = config.accounts.count
            statusLine = "Syncing \(config.accounts.count) account(s)"

            for account in config.accounts {
                let snapshot = try await buildSnapshot(for: account)
                try await pushSnapshot(snapshot, endpoint: config.localCacheEndpoint)
            }

            let now = ISO8601DateFormatter().string(from: Date())
            lastSyncedAt = now
            statusLine = "Synced \(config.accounts.count) account(s)"
        } catch {
            statusLine = error.localizedDescription
        }
    }

    private func scheduleNextSync() {
        do {
            let config = try loadConfig()

            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: config.pollIntervalSeconds, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    await self?.syncNow()
                }
            }
        } catch {
            statusLine = error.localizedDescription
        }
    }

    private func loadConfig() throws -> PulseConfig {
        let url = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent(".codexboard")
            .appendingPathComponent("accounts.json")

        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            throw PulseError.missingConfig(url)
        }

        let data = try Data(contentsOf: url)
        return try decoder.decode(PulseConfig.self, from: data)
    }

    private func buildSnapshot(for account: AccountConfig) async throws -> AccountSnapshot {
        let accessToken = try await fetchAccessToken(for: account)
        let rawUsage = try await fetchUsagePayload(for: account, accessToken: accessToken)

        return try normalizeUsage(rawUsage, account: account)
    }

    private func fetchAccessToken(for account: AccountConfig) async throws -> String {
        let sessionURL = URL(string: account.sessionEndpoint ?? "https://chatgpt.com/api/auth/session")!
        var request = URLRequest(url: sessionURL)
        request.setValue(account.chatGPTCookie, forHTTPHeaderField: "Cookie")
        request.setValue("https://chatgpt.com", forHTTPHeaderField: "Origin")

        let (data, _) = try await URLSession.shared.data(for: request)
        let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let accessToken = payload?["accessToken"] as? String

        guard let accessToken, !accessToken.isEmpty else {
            throw PulseError.invalidSessionToken
        }

        return accessToken
    }

    private func fetchUsagePayload(for account: AccountConfig, accessToken: String) async throws -> [String: Any] {
        let usageURL = URL(string: account.usageEndpoint ?? "https://chatgpt.com/backend-api/wham/usage")!
        var request = URLRequest(url: usageURL)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(account.chatGPTCookie, forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let accountHeader = account.accountHeader, !accountHeader.isEmpty {
            request.setValue(accountHeader, forHTTPHeaderField: "ChatGPT-Account-Id")
        }

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PulseError.invalidUsageResponse
        }

        return payload
    }

    private func normalizeUsage(_ payload: [String: Any], account: AccountConfig) throws -> AccountSnapshot {
        let now = ISO8601DateFormatter().string(from: Date())

        let weeklyUsed = extractInt(payload, paths: [
            ["weekly", "used_minutes"],
            ["weekly", "usedMinutes"],
            ["weekly_used_minutes"],
        ])
        let weeklyLimit = extractInt(payload, paths: [
            ["weekly", "limit_minutes"],
            ["weekly", "limitMinutes"],
            ["weekly_limit_minutes"],
        ])
        let weeklyRemaining = extractInt(payload, paths: [
            ["weekly", "remaining_minutes"],
            ["weekly", "remainingMinutes"],
            ["weekly_remaining_minutes"],
        ])
        let weeklyReset = extractString(payload, paths: [
            ["weekly", "resets_at"],
            ["weekly", "resetsAt"],
            ["weekly_resets_at"],
        ])

        let rollingUsed = extractInt(payload, paths: [
            ["rolling_5h", "used_minutes"],
            ["rollingFiveHour", "usedMinutes"],
            ["five_hour", "used_minutes"],
        ])
        let rollingLimit = extractInt(payload, paths: [
            ["rolling_5h", "limit_minutes"],
            ["rollingFiveHour", "limitMinutes"],
            ["five_hour", "limit_minutes"],
        ])
        let rollingRemaining = extractInt(payload, paths: [
            ["rolling_5h", "remaining_minutes"],
            ["rollingFiveHour", "remainingMinutes"],
            ["five_hour", "remaining_minutes"],
        ])
        let rollingReset = extractString(payload, paths: [
            ["rolling_5h", "resets_at"],
            ["rollingFiveHour", "resetsAt"],
            ["five_hour", "resets_at"],
        ])

        guard
            let weeklyUsed,
            let weeklyLimit,
            let weeklyRemaining,
            let weeklyReset,
            let rollingUsed,
            let rollingLimit,
            let rollingRemaining,
            let rollingReset
        else {
            throw PulseError.invalidUsageResponse
        }

        let weeklyPercent = percentage(used: weeklyUsed, limit: weeklyLimit)
        let rollingPercent = percentage(used: rollingUsed, limit: rollingLimit)
        let projectedRemaining = max(weeklyRemaining - rollingUsed, 0)
        let paceStatus: String

        switch weeklyPercent {
        case ..<55:
            paceStatus = "steady"
        case ..<80:
            paceStatus = "tight"
        default:
            paceStatus = "over"
        }

        let pace = PaceSnapshot(
            status: paceStatus,
            summary: "Projected reserve \(String(format: "%.1f", Double(projectedRemaining) / 60.0))h",
            detail: "Derived locally from the last weekly window and the current rolling burst."
        )

        return AccountSnapshot(
            accountId: account.id,
            label: account.label,
            email: account.email,
            workspaceLabel: account.workspaceLabel,
            plan: account.plan,
            color: account.color,
            source: account.source ?? "menu bar sync",
            lastSyncedAt: now,
            weeklyWindow: UsageWindow(
                label: "Weekly window",
                usedMinutes: weeklyUsed,
                limitMinutes: weeklyLimit,
                remainingMinutes: weeklyRemaining,
                usedPercentage: weeklyPercent,
                resetsAt: weeklyReset
            ),
            rollingWindow: UsageWindow(
                label: "Rolling 5-hour window",
                usedMinutes: rollingUsed,
                limitMinutes: rollingLimit,
                remainingMinutes: rollingRemaining,
                usedPercentage: rollingPercent,
                resetsAt: rollingReset
            ),
            pace: pace,
            history: [
                HistorySnapshot(
                    capturedAt: now,
                    weeklyUsedMinutes: weeklyUsed,
                    rollingUsedMinutes: rollingUsed,
                    note: "Live cookie capture via local menu bar feeder."
                )
            ]
        )
    }

    private func pushSnapshot(_ snapshot: AccountSnapshot, endpoint: String) async throws {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(snapshot)

        _ = try await URLSession.shared.data(for: request)
    }

    private func extractInt(_ payload: [String: Any], paths: [[String]]) -> Int? {
        for path in paths {
            if let value = extractValue(payload, path: path) as? NSNumber {
                return value.intValue
            }

            if let value = extractValue(payload, path: path) as? Int {
                return value
            }

            if let value = extractValue(payload, path: path) as? Double {
                return Int(value.rounded())
            }
        }

        return nil
    }

    private func extractString(_ payload: [String: Any], paths: [[String]]) -> String? {
        for path in paths {
            if let value = extractValue(payload, path: path) as? String {
                return value
            }
        }

        return nil
    }

    private func extractValue(_ payload: [String: Any], path: [String]) -> Any? {
        var current: Any = payload

        for segment in path {
            guard let dictionary = current as? [String: Any], let next = dictionary[segment] else {
                return nil
            }

            current = next
        }

        return current
    }

    private func percentage(used: Int, limit: Int) -> Double {
        guard limit > 0 else {
            return 0
        }

        return (Double(used) / Double(limit)) * 100
    }
}

struct PulseMenuView: View {
    @ObservedObject var coordinator: PulseCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CodexBoard Pulse")
                .font(.headline)

            Text(coordinator.statusLine)
                .font(.subheadline)

            Text("Accounts: \(coordinator.accountCount)")
                .foregroundStyle(.secondary)

            if let lastSyncedAt = coordinator.lastSyncedAt {
                Text("Last sync: \(lastSyncedAt)")
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Button("Sync now") {
                Task { @MainActor in
                    await coordinator.syncNow()
                }
            }

            Divider()

            Text("Config: ~/.codexboard/accounts.json")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .frame(width: 320)
        .padding(16)
    }
}

@main
struct CodexBoardPulseApp: App {
    @StateObject private var coordinator = PulseCoordinator()

    var body: some Scene {
        MenuBarExtra("CodexBoard Pulse", systemImage: "gauge.with.needle") {
            PulseMenuView(coordinator: coordinator)
                .task {
                    coordinator.start()
                }
        }
        .menuBarExtraStyle(.window)
    }
}
