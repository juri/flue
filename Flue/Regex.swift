//
//  Regex.swift
//  Flue
//
//  Created by Juri Pakaste on 04/03/16.
//  Copyright © 2016 Juri Pakaste. All rights reserved.
//

import Foundation

extension ConversionStepProtocol where Output == String {
    /// Checks that the input string matches the regexp. If the regular expression compilation fails, it retuns a nil step.
    public func regexp(rs: String, opts: NSRegularExpressionOptions = [], anchored: Bool = true) -> ConversionStep<String, String>? {
        guard let r = try? NSRegularExpression(pattern: rs, options: opts) else {
            return nil
        }
        return self.regexp(r, anchored: anchored)
    }

    /// Checks that the input string matches the regexp.
    public func regexp(r: NSRegularExpression, anchored: Bool = true) -> ConversionStep<String, String> {
        func convert(s: String, ctx: ConversionContext) -> ConversionResult<String, ExtractError> {
            let opts: NSMatchingOptions
            if anchored { opts = [.Anchored] } else { opts = [] }
            if r.firstMatchInString(s, options: opts, range: NSRange(location: 0, length: s.characters.count)) != nil {
                return .Success(s)
            }
            return .Failure(ctx.errorBuilder.noRegexpMatch(ctx.originalValue.name, value: s, regexp: r.pattern))
        }
        func help(ctx: ConversionContext) -> [String] {
            let msg = String.localizedStringWithFormat(NSLocalizedString("Flue.Checks.String.Regexp.Help", bundle: flueBundle(), comment: "Flue: Check regexp match: Help text. Parameters: Regexp pattern"), r.pattern)
            return self.help(ctx) + [msg]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }
}
