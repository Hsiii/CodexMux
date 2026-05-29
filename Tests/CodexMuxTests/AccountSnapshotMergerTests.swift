import XCTest
@testable import CodexMux

final class AccountSnapshotMergerTests: XCTestCase {
    func testTransientCookieOnlyRefreshPreservesCurrentSystemSeat() {
        let merger = AccountSnapshotMerger()
        let existingActive = self.makeSnapshot(
            accountId: "person@example.com::workspace-a",
            email: "person@example.com",
            workspaceId: "workspace-a",
            workspaceLabel: "Workspace A",
            source: "live system auth",
            isCurrentSystemAccount: true,
            systemAuthProfileId: "profile-1"
        )
        let cookieSnapshot = self.makeSnapshot(
            accountId: "person@example.com::cookie-seat",
            email: "person@example.com",
            workspaceId: nil,
            workspaceLabel: "Cookie Seat",
            source: "native cookie sync",
            isCurrentSystemAccount: false
        )

        let merged = merger.merge(
            existing: CachePayload(
                meta: CacheMeta(source: "test"),
                accounts: [existingActive]
            ),
            incoming: [cookieSnapshot],
            systemStateWasRefreshed: false
        )

        XCTAssertEqual(merged.accounts.count, 2)
        XCTAssertEqual(
            merged.accounts.first(where: { $0.accountId == existingActive.accountId })?.isCurrentSystemAccount,
            true
        )
    }

    func testRefreshedEmptySystemStateClearsCurrentSystemSeat() {
        let merger = AccountSnapshotMerger()
        let existingActive = self.makeSnapshot(
            accountId: "person@example.com::workspace-a",
            email: "person@example.com",
            workspaceId: "workspace-a",
            workspaceLabel: "Workspace A",
            source: "live system auth",
            isCurrentSystemAccount: true,
            systemAuthProfileId: "profile-1"
        )

        let merged = merger.merge(
            existing: CachePayload(
                meta: CacheMeta(source: "test"),
                accounts: [existingActive]
            ),
            incoming: [],
            systemStateWasRefreshed: true
        )

        XCTAssertEqual(merged.accounts.count, 1)
        XCTAssertEqual(merged.accounts[0].isCurrentSystemAccount, false)
    }

    func testSeatSwapFallbackPreservesWorkspaceBackedMetadata() {
        let merger = AccountSnapshotMerger()
        let existingWorkspaceSeat = self.makeSnapshot(
            accountId: "person@example.com::workspace-a",
            email: "person@example.com",
            workspaceId: "workspace-a",
            workspaceLabel: "Workspace A",
            source: "live system auth",
            isCurrentSystemAccount: true,
            systemAuthProfileId: "profile-1",
            weeklyAvailable: true
        )
        let incomingFallbackSeat = self.makeSnapshot(
            accountId: "person@example.com::personal",
            email: "person@example.com",
            workspaceId: nil,
            workspaceLabel: "Personal",
            source: "live system auth",
            isCurrentSystemAccount: true,
            systemAuthProfileId: "profile-1",
            weeklyAvailable: false
        )

        let merged = merger.merge(
            existing: CachePayload(
                meta: CacheMeta(source: "test"),
                accounts: [existingWorkspaceSeat]
            ),
            incoming: [incomingFallbackSeat],
            systemStateWasRefreshed: true
        )

        XCTAssertEqual(merged.accounts.count, 1)
        XCTAssertEqual(merged.accounts[0].accountId, existingWorkspaceSeat.accountId)
        XCTAssertEqual(merged.accounts[0].workspaceId, existingWorkspaceSeat.workspaceId)
        XCTAssertEqual(merged.accounts[0].workspaceLabel, existingWorkspaceSeat.workspaceLabel)
        XCTAssertEqual(merged.accounts[0].isCurrentSystemAccount, true)
    }

    func testCoexistingSameEmailWorkspaceSeatsRemainDistinct() {
        let merger = AccountSnapshotMerger()
        let workspaceA = self.makeSnapshot(
            accountId: "person@example.com::workspace-a",
            email: "person@example.com",
            workspaceId: "workspace-a",
            workspaceLabel: "Workspace A",
            source: "live system auth",
            isCurrentSystemAccount: true,
            systemAuthProfileId: "profile-1"
        )
        let workspaceB = self.makeSnapshot(
            accountId: "person@example.com::workspace-b",
            email: "person@example.com",
            workspaceId: "workspace-b",
            workspaceLabel: "Workspace B",
            source: "live system auth",
            isCurrentSystemAccount: false,
            systemAuthProfileId: "profile-1"
        )

        let merged = merger.merge(
            existing: CachePayload(
                meta: CacheMeta(source: "test"),
                accounts: []
            ),
            incoming: [workspaceA, workspaceB],
            systemStateWasRefreshed: true
        )

        XCTAssertEqual(merged.accounts.count, 2)
        XCTAssertNotNil(merged.accounts.first(where: { $0.accountId == workspaceA.accountId }))
        XCTAssertNotNil(merged.accounts.first(where: { $0.accountId == workspaceB.accountId }))
    }

    func testStablePersonalWorkspaceSupersedesStaleUnscopedPersonalSystemSeat() {
        let merger = AccountSnapshotMerger()
        let stalePersonal = self.makeSnapshot(
            accountId: "person@example.com",
            email: "person@example.com",
            workspaceId: nil,
            workspaceLabel: "",
            plan: "Codex Free",
            source: "live system auth",
            isCurrentSystemAccount: false,
            systemAuthProfileId: "profile-1"
        )
        let currentPersonal = self.makeSnapshot(
            accountId: "person@example.com::user-abc",
            email: "person@example.com",
            workspaceId: "user-abc",
            workspaceLabel: "",
            plan: "Codex Free",
            source: "live system auth",
            isCurrentSystemAccount: true,
            systemAuthProfileId: "profile-1"
        )

        let merged = merger.merge(
            existing: CachePayload(
                meta: CacheMeta(source: "test"),
                accounts: [stalePersonal]
            ),
            incoming: [currentPersonal],
            systemStateWasRefreshed: true
        )

        XCTAssertEqual(merged.accounts.map(\.accountId), [currentPersonal.accountId])
        XCTAssertEqual(merged.accounts[0].isCurrentSystemAccount, true)
    }

    func testWorkspaceBackedTeamSeatDoesNotSupersedeUnscopedPersonalSystemSeat() {
        let merger = AccountSnapshotMerger()
        let personal = self.makeSnapshot(
            accountId: "person@example.com",
            email: "person@example.com",
            workspaceId: nil,
            workspaceLabel: "",
            plan: "Codex Free",
            source: "live system auth",
            isCurrentSystemAccount: false,
            systemAuthProfileId: "profile-1"
        )
        let team = self.makeSnapshot(
            accountId: "person@example.com::workspace-a",
            email: "person@example.com",
            workspaceId: "workspace-a",
            workspaceLabel: "Workspace A",
            plan: "Codex Team",
            source: "live system auth",
            isCurrentSystemAccount: true,
            systemAuthProfileId: "profile-1"
        )

        let merged = merger.merge(
            existing: CachePayload(
                meta: CacheMeta(source: "test"),
                accounts: [personal]
            ),
            incoming: [team],
            systemStateWasRefreshed: true
        )

        XCTAssertEqual(merged.accounts.count, 2)
        XCTAssertNotNil(merged.accounts.first(where: { $0.accountId == personal.accountId }))
        XCTAssertNotNil(merged.accounts.first(where: { $0.accountId == team.accountId }))
    }

    private func makeSnapshot(
        accountId: String,
        email: String,
        workspaceId: String?,
        workspaceLabel: String,
        plan: String = "Codex Team",
        source: String,
        isCurrentSystemAccount: Bool?,
        systemAuthProfileId: String? = nil,
        weeklyAvailable: Bool = true
    ) -> AccountSnapshot {
        AccountSnapshot(
            accountId: accountId,
            label: email,
            email: email,
            workspaceId: workspaceId,
            workspaceLabel: workspaceLabel,
            plan: plan,
            source: source,
            systemAuthProfileId: systemAuthProfileId,
            isCurrentSystemAccount: isCurrentSystemAccount,
            lastSyncedAt: "2026-05-28T00:00:00Z",
            weeklyWindow: UsageWindow(
                available: weeklyAvailable,
                label: "Weekly window",
                usedMinutes: 10,
                limitMinutes: 100,
                usedPercentage: 10,
                resetsAt: "2026-05-29T00:00:00Z"
            ),
            rollingWindow: UsageWindow(
                available: true,
                label: "Rolling 5-hour window",
                usedMinutes: 5,
                limitMinutes: 50,
                usedPercentage: 10,
                resetsAt: "2026-05-28T05:00:00Z"
            )
        )
    }
}
