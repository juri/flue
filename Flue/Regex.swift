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
    public func regexp(_ rs: String, opts: NSRegularExpression.Options = [], anchored: Bool = true) -> ConversionStep<String, String>? {
        guard let r = try? NSRegularExpression(pattern: rs, options: opts) else {
            return nil
        }
        return self.regexp(r, anchored: anchored)
    }

    /// Checks that the input string matches the regexp.
    public func regexp(_ r: NSRegularExpression, anchored: Bool = true) -> ConversionStep<String, String> {
        func convert(_ s: String, ctx: ConversionContext) -> ConversionResult<String> {
            let opts: NSRegularExpression.MatchingOptions
            if anchored { opts = [.anchored] } else { opts = [] }
            if r.firstMatch(in: s, options: opts, range: NSRange(location: 0, length: s.characters.count)) != nil {
                return .success(s)
            }
            return .failure(ctx.errorBuilder.noRegexpMatch(ctx.originalValue.name, value: s, regexp: r.pattern))
        }
        func help(_ ctx: ConversionContext) -> [String] {
            let msg = String.localizedStringWithFormat(ctx.stringLoader("Flue.Checks.String.Regexp.Help", "Flue: Check regexp match: Help text. Parameters: Regexp pattern"), r.pattern)
            return self.help(ctx) + [msg]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }
}
