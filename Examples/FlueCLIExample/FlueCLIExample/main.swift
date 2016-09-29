//
//  main.swift
//  FlueCLIExample
//
//  Created by Juri Pakaste on 06/04/16.
//  Copyright © 2016 Juri Pakaste. All rights reserved.
//

import Foundation

func newStringLoader() -> StringLoader {
    let localizations = readLocalizations()
    return { (key, _) in
        return localizations[key]!
    }
}

let vp = ValueParser(stringLoader: newStringLoader())
let dp = DictParser(dict: ProcessInfo.processInfo.environment, valueParser: vp)
do {
    let _ = try dp.extract("FOO").asInt().required()
} catch {
    print("Error: \(error)")
}
