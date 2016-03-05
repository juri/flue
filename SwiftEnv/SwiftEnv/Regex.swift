//
//  Regex.swift
//  SwiftEnv
//
//  Created by Juri Pakaste on 04/03/16.
//  Copyright © 2016 Juri Pakaste. All rights reserved.
//

import Foundation

extension ConversionStepProtocol where Output == String {
    func regexp(rs: String, opts: NSRegularExpressionOptions = [], anchored: Bool = true) -> ConversionStep<String, String>? {
        guard let r = try? NSRegularExpression(pattern: rs, options: opts) else {
            return nil
        }
        return self.regexp(r, anchored: anchored)
    }

    func regexp(r: NSRegularExpression, anchored: Bool = true) -> ConversionStep<String, String> {
        func convert(s: String, ov: OriginalValue) -> ConversionResult<String, ExtractError> {
            let opts: NSMatchingOptions
            if anchored { opts = [.Anchored] } else { opts = [] }
            if r.firstMatchInString(s, options: opts, range: NSRange(location: 0, length: s.characters.count)) != nil {
                return .Success(s)
            }
            return .Failure(ExtractError.RegexpError(name: ov.name, value: s, regexp: r.pattern))
        }
        func help() -> [String] {
            return self.help() + ["Must match regular expression \(r.pattern)"]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help)
    }
}
