//: Playground - noun: a place where people can play

import Cocoa
import Flue

struct Settings {
    var debug: Bool
    var port: Int
    var config: Any
    var key: String
    var path: [String]
}

enum SettingsOrError {
    case success(Settings)
    case error(String)
}

func readSettings(env: [String: String]) -> (SettingsOrError, String) {
    let vp = Flue.ValueParser()
    let dp = Flue.DictParser(dict: env, valueParser: vp)

    let conversions = Flue.Conversions()

    let debugExtract = conversions.add(dp.extract("DEBUG").asBool())
    let portExtract = conversions.add(dp.extract("PORT").asInt())
    let configExtract = conversions.add(dp.extract("CONFIG").asJSON())
    let keyExtract = conversions.add(dp.extract("KEY").minLength(6).addHelp("Encryption key.", prefix: false))
    let pathExtract = conversions.add(dp.extract("PATH").asType({ val, ctx in val.components(separatedBy: ":") }, help: "String with components separated by :"))

    let helps = conversions.usage()
    let maxNameWidth = helps.reduce(0) { max($0, $1[0].characters.count) }
    let help = helps.map({ formatHelp(parts: $0, nameWidth: maxNameWidth) }).joined(separator: "\n")

    do {
        return (.success(Settings(
            debug: try debugExtract.required(),
            port: try portExtract.required(),
            config: try configExtract.required(),
            key: try keyExtract.required(),
            path: try pathExtract.required()
        )), help)
    } catch {
        return (.error(conversions.errors().map { String(describing: $0) }.joined(separator: ", ")), help)
    }
}

func readEnv(env: [String: String]) {
    let (res, help) = readSettings(env: env)
    print("Read from environment:")
    print("help: \(help)")
    switch res {
    case let .success(s): print("Settings: \(s)")
    case let .error(e): print("Error: \(e)")
    }
}

func readExample() {
    readEnv(env: ["DEBUG": "yes", "PORT": "42158", "CONFIG": "{\"asdf\": \"bar\"}", "KEY": "qwertyui", "PATH": ProcessInfo.processInfo.environment["PATH"]!])
    readEnv(env: [:])
}

func formatHelp(parts: [String], nameWidth: Int) -> String {
    return String(format: "%@ -- %@", parts[0].padding(toLength: nameWidth, withPad: " ", startingAt: 0), parts[1..<parts.count].joined(separator: ". "))
}

readExample()

