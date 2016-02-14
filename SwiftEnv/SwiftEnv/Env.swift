//
//  Env.swift
//  SwiftEnv
//
//  Created by Juri Pakaste on 09/02/16.
//  Copyright © 2016 Juri Pakaste. All rights reserved.
//

import Foundation

private func parseInt(name: String, value: String) throws -> Int? {
    let fmt = NSNumberFormatter()
    fmt.locale = NSLocale(localeIdentifier: "POSIX")
    fmt.maximumFractionDigits = 0

    let nopt = fmt.numberFromString(value).map {$0 as Int}
    guard let n = nopt else {
        throw ExtractError.FormatError(name: name, value: value)
    }
    return n
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

    func asInt() throws -> ExtractedTypedValue<Int> {
        let ival = try self.value.flatMap({ try parseInt(self.name, value: $0) })
        return ExtractedTypedValue<Int>(name: self.name, value: ival)
    }
}

func extractFrom(c: [String: String], key: String) -> ExtractedString {
    return ExtractedString(name: key, value: c[key])
}

