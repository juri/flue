//
//  Env.swift
//  SwiftEnv
//
//  Created by Juri Pakaste on 09/02/16.
//  Copyright © 2016 Juri Pakaste. All rights reserved.
//

import Foundation

class ValueParser {
    private let integerFormatter: NSNumberFormatter

    init(locale: NSLocale = NSLocale(localeIdentifier: "POSIX")) {
        let integerFormatter = NSNumberFormatter()
        integerFormatter.locale = locale
        integerFormatter.maximumFractionDigits = 0
        self.integerFormatter = integerFormatter
    }

    private func parseInt(name: String, value: String) throws -> Int? {
        guard let n = self.integerFormatter.numberFromString(value) as? Int else {
            throw ExtractError.FormatError(name: name, value: value)
        }
        return n
    }

    func extractFrom(c: [String: String], key: String) -> ExtractedString {
        return ExtractedString(name: key, value: c[key], parser: self)
    }
}

enum ExtractError: ErrorType {
    case ValueMissing(name: String)
    case FormatError(name: String, value: String)
}

protocol ValueKeeper {
    typealias ValueType

    var name: String { get }
    var value: ValueType? { get }

    func required() throws -> ValueType
    func defaultValue(dv: ValueType) -> ValueType
}

extension ValueKeeper {
    func required() throws -> ValueType {
        if let v = self.value {
            return v
        }
        throw ExtractError.ValueMissing(name: self.name)
    }

    func defaultValue(dv: ValueType) -> ValueType {
        if let v = self.value {
            return v
        }
        return dv
    }
}

struct ExtractedTypedValue<T>: ValueKeeper {
    let name: String
    let value: T?
}

struct ExtractedString: ValueKeeper {
    let name: String
    let value: String?
    let parser: ValueParser

    func asInt() throws -> ExtractedTypedValue<Int> {
        let ival = try self.value.flatMap({ try self.parser.parseInt(self.name, value: $0) })
        return ExtractedTypedValue<Int>(name: self.name, value: ival)
    }
}

