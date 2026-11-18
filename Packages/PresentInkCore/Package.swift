// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "PresentInkCore", defaultLocalization: "de", platforms: [.macOS("27.0"), .iOS("27.0")], products: [.library(name: "PresentInkCore", targets: ["PresentInkCore"])], targets: [.target(name: "PresentInkCore", resources: [.process("Resources")]), .testTarget(name: "PresentInkCoreTests", dependencies: ["PresentInkCore"])])
