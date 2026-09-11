// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DragDrop",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "DragDrop", targets: ["DragDrop"]),
        // Support code for Demo/. Not part of the library's public surface;
        // it lives here so its geometry and fixtures get fast unit tests.
        .library(name: "DemoKit", targets: ["DemoKit"])
    ],
    targets: [
        .target(name: "DragDrop"),
        .target(name: "DemoKit"),
        .testTarget(name: "DragDropTests", dependencies: ["DragDrop"]),
        .testTarget(name: "DemoKitTests", dependencies: ["DemoKit"])
    ]
)
