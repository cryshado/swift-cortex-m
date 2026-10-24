// swift-tools-version: 6.4

import PackageDescription

let setupPluginTarget: Target = .plugin(
    name: "CortexMSetup",
    capability: .command(
        intent: .custom(
            verb: "cortex-m-setup",
            description: "Generate project files for a Cortex-M target",
        ),
        permissions: [
            .writeToPackageDirectory(reason: "Writes the build configuration.")
        ],
    ),
)

let products: [Product] = [
    .library(name: "CortexMRuntime", targets: ["CortexMRuntime"]),
    .library(name: "CortexMCore", targets: ["CortexMCore"]),
    .plugin(name: "CortexMSetup", targets: ["CortexMSetup"]),
]

let targets: [Target] = [
    .target(name: "CortexMRuntime", dependencies: ["CCortexMRuntime"]),
    .target(name: "CCortexMRuntime"),
    .target(name: "CortexMCore", dependencies: ["CCortexMCore"]),
    .target(name: "CCortexMCore"),
    setupPluginTarget,
]

let package = Package(
    name: "swift-cortex-m",
    platforms: [.macOS(.v15)],
    products: products,
    targets: targets,
)
