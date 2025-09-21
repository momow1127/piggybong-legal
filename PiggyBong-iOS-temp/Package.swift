// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PiggyBong",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PiggyBong",
            targets: ["PiggyBong"]),
    ],
    dependencies: [
        // Supabase Swift SDK
        .package(
            url: "https://github.com/supabase/supabase-swift.git",
            from: "2.0.0"
        )
    ],
    targets: [
        .target(
            name: "PiggyBong",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "PiggyBongTests",
            dependencies: ["PiggyBong"],
            path: "Tests"
        ),
    ]
)