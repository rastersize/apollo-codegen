// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ApolloCodegen",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "apollo-codegen", targets: ["ApolloCodegen"]),
    ],
    dependencies: [
        // The actual Apollo library
        .package(
            name: "Apollo",
            url: "https://github.com/apollographql/apollo-ios.git",
            /// Make sure this version matches the version in your iOS project!
            .upToNextMinor(from: "0.42.0")
        ),
        // The official Swift argument parser.
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            .upToNextMinor(from: "0.4.0")
        ),
    ],
    targets: [
        .target(
            name: "ApolloCodegen",
            dependencies: [
                .product(name: "ApolloCodegenLib", package: "Apollo"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "ApolloCodegenTests",
            dependencies: ["ApolloCodegen"]
        ),
    ]
)
