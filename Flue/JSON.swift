//
//  JSON.swift
//  Flue
//
//  Created by Juri Pakaste on 04/03/16.
//  Copyright © 2016 Juri Pakaste. All rights reserved.
//

import Foundation

extension ConversionStepProtocol where Output == String {
    /// Parses the input string as JSON.
    public func asJSON(allowFragments: Bool = false) -> ConversionStep<String, AnyObject> {
        func convert(s: String, ctx: ConversionContext) -> ConversionResult<AnyObject, ExtractError> {
            do {
                let opts: NSJSONReadingOptions = allowFragments ? [.AllowFragments] : []
                let ob = try NSJSONSerialization.JSONObjectWithData(s.dataUsingEncoding(NSUTF8StringEncoding)!, options: opts)
                return .Success(ob)
            } catch {
                return .Failure(ctx.errorBuilder.fromError(error))
            }
        }
        return ConversionStep(
            input: self.readValue,
            convert: convert,
            help: { ctx in self.help(ctx) + [ctx.stringLoader("Flue.Extract.Type.JSON", "Flue: Extract value as JSON: Help text")] },
            context: self.context)
    }
}
