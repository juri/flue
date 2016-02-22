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
    private let env: [String: String]

    init(env: [String: String], locale: NSLocale = NSLocale(localeIdentifier: "POSIX")) {
        let integerFormatter = NSNumberFormatter()
        integerFormatter.locale = locale
        integerFormatter.maximumFractionDigits = 0
        self.integerFormatter = integerFormatter
        self.env = env
    }

    private func parseInt(name: String, value: String) throws -> Int? {
        guard let n = self.integerFormatter.numberFromString(value) as? Int else {
            throw ExtractError.FormatError(name: name, value: value, vtype: "Integer")
        }
        return n
    }

    func extract(key: String) -> ExtractedString {
        return ExtractedString(name: key, value: self.env[key], parser: self)
    }
}

enum ExtractError: ErrorType {
    case ValueMissing(name: String)
    case FormatError(name: String, value: String, vtype: String)

    var description: String {
        switch self {
        case .ValueMissing(let name):
            return "Required value \(name) wasn't found"
        case .FormatError(let name, let value, let vtype):
            return "\(name) value \(value) can't be interpreted as \(vtype)"
        }
    }
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

    func asBool() throws -> ExtractedTypedValue<Bool> {
        let bval = self.value.flatMap({ ($0 as NSString).boolValue })
        return ExtractedTypedValue<Bool>(name: self.name, value: bval)
    }
}

