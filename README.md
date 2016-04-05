# Flue

[![Build Status](https://travis-ci.org/juri/flue.svg?branch=master)](https://travis-ci.org/juri/flue)

Flue is a Swift library. It extracts, converts and validates values from user input. It produces help strings describing those operations.

Flue supports both unnamed values and named values source like the environment.

## Requirements

Flue is written in Swift 2.2. It requires Foundation. It has been tested on a Mac with Xcode 7.3.

## Example

```swift
struct Settings {
    var debug: Bool
    var port: Int
    var config: AnyObject
    var key: String
    var path: [String]
}

enum SettingsOrError {
    case Success(Settings)
    case Error(String)
}

func formatHelp(parts: [String], nameWidth: Int) -> String {
    return String(format: "%@ -- %@", parts[0].stringByPaddingToLength(nameWidth, withString: " ", startingAtIndex: 0), parts[1..<parts.count].joinWithSeparator(". "))
}

func readSettings(env: [String: String]) -> (SettingsOrError, String) {
    let vp = Flue.ValueParser()
    let dp = Flue.DictParser(dict: env, valueParser: vp)

    let debugExtract = dp.extract("DEBUG").asBool()
    let portExtract = dp.extract("PORT").asInt()
    let configExtract = dp.extract("CONFIG").asJSON()
    let keyExtract = dp.extract("KEY").minLength(6).addHelp("Encryption key.", prefix: false)
    let pathExtract = dp.extract("PATH").asType({ val, ctx in val.componentsSeparatedByString(":") }, help: "String with components separated by :")

    let usageProviders: [UsageProvider] = [debugExtract, portExtract, configExtract, keyExtract, pathExtract]

    let helps = usageProviders.map { $0.usage() }
    let maxNameWidth = helps.reduce(0) { max($0, $1[0].characters.count) }
    let help = helps.map({ formatHelp($0, nameWidth: maxNameWidth) }).joinWithSeparator("\n")

    do {
        return (.Success(Settings(
            debug: try debugExtract.required(),
            port: try portExtract.required(),
            config: try configExtract.required(),
            key: try keyExtract.required(),
            path: try pathExtract.required()
            )), help)
    } catch {
        return (.Error(String(error)), help)
    }
}

func readExample() {
    let env = ["DEBUG": "yes", "PORT": "42158", "CONFIG": "{\"asdf\": \"bar\"}", "KEY": "qwertyui", "PATH": NSProcessInfo.processInfo().environment["PATH"]!]
    let (res, help) = readSettings(env)
    print("help: \(help)")
    print("res: \(res)")
}
```

You'll get parsed values in the Settings object and a help string that looks like this:


```
DEBUG  -- Boolean: true if string starts with [YyTt1-9]
PORT   -- Integer
CONFIG -- JSON Data
KEY    -- Minimum length: 6. Encryption key.
PATH   -- String with components separated by :
```



## License

Flue is released under the MIT license. See LICENSE for details.
