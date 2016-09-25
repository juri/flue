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
    public func asJSON(_ allowFragments: Bool = false) -> ConversionStep<String, Any> {
        func convert(_ s: String, ctx: ConversionContext) -> ConversionResult<Any> {
            do {
                let opts: JSONSerialization.ReadingOptions = allowFragments ? [.allowFragments] : []
                let ob = try JSONSerialization.jsonObject(with: s.data(using: String.Encoding.utf8)!, options: opts)
                return .success(ob)
            } catch {
                return .failure(ctx.errorBuilder.fromError(error))
            }
        }
        return ConversionStep(
            input: self.readValue,
            convert: convert,
            help: { ctx in self.help(ctx) + [ctx.stringLoader("Flue.Extract.Type.JSON", "Flue: Extract value as JSON: Help text")] },
            context: self.context)
    }
}
