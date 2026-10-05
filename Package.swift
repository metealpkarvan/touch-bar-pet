// swift-tools-version: 5.7
import PackageDescription
let package = Package(name: "TouchBarPet", platforms: [.macOS(.v11)], products: [
    .executable(name: "TouchBarPet", targets: ["TouchBarPet"]),
    .library(name: "PetCore", targets: ["PetCore"]),
    .executable(name: "PetRulesTests", targets: ["PetRulesTests"])
], targets: [
    .target(name: "PetCore"),
    .executableTarget(name: "TouchBarPet", dependencies: ["PetCore"]),
    .executableTarget(name: "PetRulesTests", dependencies: ["PetCore"], path: "Tests/PetRulesTests")
], swiftLanguageVersions: [.v5])
