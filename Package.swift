import PackageDescription

let package = Package(
    name: "Flue",
    targets: [
        Target(name: "Flue"),
        Target(name: "FlueTests", dependencies: [.Target(name: "Flue")])
    ]
)
