//
//  main.swift
//  FlueCLIExample
//
//  Created by Juri Pakaste on 06/04/16.
//  Copyright © 2016 Juri Pakaste. All rights reserved.
//

import Foundation

func readLocalizations() -> [String: String] {
    var size: UInt = 0
    let localizationSection = getsectdata("__LOCALIZATIONS", "__base", &size)
    assert(size > 0)
    let data = NSData(bytes: UnsafeMutablePointer<Void>(localizationSection), length: Int(size))
    let localizationsString = NSString(data: data, encoding: NSUTF8StringEncoding)!

    let localizationPList = localizationsString.propertyListFromStringsFileFormat()!
    return localizationPList as! [String: String]
}

func newStringLoader() -> StringLoader {
    let localizations = readLocalizations()
    return { (key, _) in
        return localizations[key]!
    }
}

let vp = ValueParser(stringLoader: newStringLoader())
let dp = DictParser(dict: NSProcessInfo.processInfo().environment, valueParser: vp)
do {
    try dp.extract("FOO").asInt().required()
} catch {
    print("Error: \(error)")
}
