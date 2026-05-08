// swift-tools-version: 6.1
// This is a Skip (https://skip.dev) package.
import PackageDescription

let package = Package(
	name: "cup-gitea",
	defaultLocalization: "en",
	platforms: [.iOS(.v16), .macOS(.v13)],
	products: [
		.library(name: "Cup", type: .dynamic, targets: ["Cup"]),
		.library(name: "GiteaAPI", type: .dynamic, targets: ["GiteaAPI"]),
	],
	dependencies: [
		.package(url: "https://source.skip.tools/skip.git", from: "1.8.13"),
		.package(url: "https://source.skip.tools/skip-fuse-ui.git", from: "1.15.0"),
		.package(url: "https://github.com/apple/swift-openapi-generator", from: "1.12.0"),
		.package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.11.0"),
		.package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.3.0"),
		.package(url: "https://github.com/swift-server/swift-openapi-async-http-client", from: "1.5.0"),
	],
	targets: [
		.target(
			name: "GiteaAPI",
			dependencies: [
				.product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
				.product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
				.product(name: "OpenAPIAsyncHTTPClient", package: "swift-openapi-async-http-client"),
			], plugins: [.plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")]),
		.target(
			name: "Cup",
			dependencies: [
				.product(name: "SkipFuseUI", package: "skip-fuse-ui"),
				.target(name: "GiteaAPI"),
			], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
	]
)
