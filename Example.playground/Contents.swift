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
    case Success(Settings)
    case Error(String)
}

func formatHelp(parts: [String], nameWidth: Int) -> String {
    return String(format: "%@ -- %@", parts[0].padding(toLength: nameWidth, withPad: " ", startingAt: 0), parts[1..<parts.count].joined(separator: ". "))
}

func readSettings(env: [String: String]) -> (SettingsOrError, String) {
    let vp = Flue.ValueParser()
    let dp = Flue.DictParser(dict: env, valueParser: vp)

    let debugExtract = dp.extract("DEBUG").asBool()
    let portExtract = dp.extract("PORT").asInt()
    let configExtract = dp.extract("CONFIG").asJSON()
    let keyExtract = dp.extract("KEY").minLength(6).addHelp("Encryption key.", prefix: false)
    let pathExtract = dp.extract("PATH").asType({ val, ctx in val.components(separatedBy: ":") }, help: "String with components separated by :")

    let usageProviders: [UsageProvider] = [debugExtract, portExtract, configExtract, keyExtract, pathExtract]

    let helps = usageProviders.map { $0.usage() }
    let maxNameWidth = helps.reduce(0) { max($0, $1[0].characters.count) }
    let help = helps.map({ formatHelp(parts: $0, nameWidth: maxNameWidth) }).joined(separator: "\n")

    do {
        return (.Success(Settings(
            debug: try debugExtract.required(),
            port: try portExtract.required(),
            config: try configExtract.required(),
            key: try keyExtract.required(),
            path: try pathExtract.required()
        )), help)
    } catch {
        return (.Error(String(describing: error)), help)
    }
}

func readExample() {
    let env = ["DEBUG": "yes", "PORT": "42158", "CONFIG": "{\"asdf\": \"bar\"}", "KEY": "qwertyui", "PATH": ProcessInfo.processInfo.environment["PATH"]!]
    let (res, help) = readSettings(env: env)
    print("help: \(help)")
    print("res: \(res)")
}

readExample()

