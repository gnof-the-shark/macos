// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RemoteCam",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "RemoteCam", targets: ["RemoteCam"]),
    ],
    targets: [
        .target(
            name: "RemoteCam",
            path: ".",
            exclude: ["README.md", ".github"],
            sources: ["ContentView.swift", "CameraManager.swift"]
        )
    ]
)
