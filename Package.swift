// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CodexBoardPulse",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "CodexBoardPulse", targets: ["CodexBoardPulse"])
    ],
    targets: [
        .executableTarget(
            name: "CodexBoardPulse",
            path: ".",
            exclude: ["README.md", ".gitignore"],
            sources: [
                "App.swift",
                "Model.swift",
                "Path.swift",
                "Store.swift",
                "Pulse.swift",
                "Format.swift",
                "Card.swift",
                "Manage.swift",
                "Menu.swift",
            ]
        )
    ]
)
