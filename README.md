# Flue

[![Build Status](https://travis-ci.org/juri/flue.svg?branch=master)](https://travis-ci.org/juri/flue)

Flue is a Swift library. It extracts, converts and validates values from user input. It produces help strings describing those operations.

Flue supports both unnamed values and named values source like the environment.

## Requirements

Flue is written in Swift 3.0. It requires Foundation. It has been tested on a Mac with Xcode 8.0.

## Example

This code is from `Example.playground`:

```swift
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
```

Calling `readExample()` will get you output like this:


```
Read from environment:
help: DEBUG  -- Boolean: true if string starts with [YyTt1-9]
PORT   -- Integer
CONFIG -- JSON Data
KEY    -- Minimum length: 6. Encryption key.
PATH   -- String with components separated by :
Settings: Settings(debug: true, port: 42158, config: {
    asdf = bar;
}, key: "qwertyui", path: ["/usr/bin", "/bin", "/usr/sbin", "/sbin"])
Read from environment:
help: DEBUG  -- Boolean: true if string starts with [YyTt1-9]
PORT   -- Integer
CONFIG -- JSON Data
KEY    -- Minimum length: 6. Encryption key.
PATH   -- String with components separated by :
Error: Required value DEBUG wasn't found, Required value PORT wasn't found, Required value CONFIG wasn't found, Required value KEY wasn't found, Required value PATH wasn't found
```

## Localization

Flue contains user-visible messages. By default they are loaded with the standard Foundation localization APIs from the bundle containing the `ValueParser` class, but the system can be overridden by specifying a custom `StringLoader` to the `ValueParser` instance.

If you wish to use Foundation `NSBundle`-based string loading mechanism, as Flue does by default, but want to load the strings from another bundle, you can use the `stringBundleLoader` helper function to construct a loader that uses `NSLocalizedString` with your desired bundle.

If you don't want to use `NSBundle`, like when you're building a standalone CLI executable, you can construct an arbitrary `StringLoader` function. One approach is to embed the localizations in the binary with the linker; see `Examples/FlueCLIExample` for a sample. See "Other Linker Flags" in the project and the loading code in `main.swift`. Basically you'll need to specify extra linker flags, like:

```
-Wl,-sectcreate,__LOCALIZATIONS,__base,../../Flue/en.lproj/Localizable.strings,-segprot,__LOCALIZATIONS,r,r
```

And then you can load them with `getsectdata` and construct a dictionary with `propertyListFromStringsFileFormat`.

## License

Flue is released under the MIT license. See LICENSE for details.
