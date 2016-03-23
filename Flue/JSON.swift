//
//  JSON.swift
//  Flue
//
//  Created by Juri Pakaste on 04/03/16.
//  Copyright © 2016 Juri Pakaste. All rights reserved.
//

import Foundation

extension ExtractedString {
    /// Parses the input string as JSON.
    func asJSON(allowFragments: Bool = false) -> ConversionStep<String, AnyObject> {
        func convert(s: String, ctx: ConversionContext) -> ConversionResult<AnyObject, ExtractError> {
            do {
                let opts: NSJSONReadingOptions = allowFragments ? [.AllowFragments] : []
                let ob = try NSJSONSerialization.JSONObjectWithData(s.dataUsingEncoding(NSUTF8StringEncoding)!, options: opts)
                return .Success(ob)
            } catch {
                return .Failure(ExtractError.fromError(error))
            }
        }
        return ConversionStep(input: self.inputForReader, convert: convert, help: { _ in self.help("JSON Data") }, context: self.conversionContext)
    }
}
