// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "PresentInkLink", platforms: [.macOS("27.0"), .iOS("27.0")], products: [.library(name: "PresentInkLink", targets: ["PresentInkLink"])], dependencies: [.package(path: "../PresentInkCore")], targets: [.target(name: "PresentInkLink", dependencies: ["PresentInkCore"]), .testTarget(name: "PresentInkLinkTests", dependencies: ["PresentInkLink"])], swiftLanguageModes: [.v5])
