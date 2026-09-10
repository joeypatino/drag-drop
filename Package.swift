// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DragDrop",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "DragDrop", targets: ["DragDrop"])
    ],
    targets: [
        .target(name: "DragDrop"),
        .testTarget(name: "DragDropTests", dependencies: ["DragDrop"])
    ]
)
