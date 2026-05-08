// swift-tools-version: 6.1
// This is a Skip (https://skip.dev) package.
import PackageDescription

let package = Package(
    name: "cup-gitea",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Cup", type: .dynamic, targets: ["Cup"]),
        .library(name: "GiteaAPI", type: .dynamic, targets: ["GiteaAPI"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.8.13"),
        .package(url: "https://source.skip.tools/skip-fuse-ui.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.6.0"),
		.package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.7.0"),
		.package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0"),
    ],
    targets: [
        .target(name: "GiteaAPI", dependencies: [
            .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
            .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
        ], plugins: [.plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")]),
        .target(name: "Cup", dependencies: [
            .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
            .target(name: "GiteaAPI"),
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
