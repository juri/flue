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

    private func parseInt(name: String, value: String) throws -> Int {
        guard let n = self.integerFormatter.numberFromString(value) as? Int else {
            throw ExtractError.FormatError(name: name, value: value, expectType: "Integer")
        }
        return n
    }

    func extract(key: String) -> ExtractedString {
        return ExtractedString(name: key, inputValue: self.env[key], parser: self)
    }
}

enum ExtractError: ErrorType, CustomStringConvertible, Equatable {
    case ValueMissing(name: String)
    case FormatError(name: String, value: String, expectType: String)
    case IntRangeError(name: String, value: Int, range: Range<Int>)
    case OtherError(String)
    indirect case CollectedErrors([ExtractError])

    var description: String {
        switch self {
        case .ValueMissing(let name):
            return "Required value \(name) wasn't found"
        case .FormatError(let name, let value, let expectType):
            return "Key \"\(name)\" format error. Had value \(value), not \(expectType)"
        case let .IntRangeError(name, value, range):
            return "Key \(name) had value \(value), not in range \(range)"
        case .OtherError(let msg):
            return msg
        case .CollectedErrors(let e):
            return e.map {$0.description}.joinWithSeparator(", ")
        }
    }

    static func fromError(e: ErrorType) -> ExtractError {
        let errorDesc: String
        if let ep = e as? CustomStringConvertible {
            errorDesc = ep.description
        } else {
            errorDesc = "Unknown error"
        }
        return .OtherError(errorDesc)
    }
}

func ==(ee1: ExtractError, ee2: ExtractError) -> Bool {
    switch (ee1, ee2) {
    case let (.ValueMissing(n1), .ValueMissing(n2)):
        return n1 == n2
    case let (.FormatError(name1, value1, expectType1), .FormatError(name2, value2, expectType2)):
        return name1 == name2 && value1 == value2 && expectType1 == expectType2
    case let (.IntRangeError(name1, value1, range1), .IntRangeError(name2, value2, range2)):
        return name1 == name2 && value1 == value2 && range1 == range2
    case let (.OtherError(v1), .OtherError(v2)):
        return v1 == v2
    case let (.CollectedErrors(c1), .CollectedErrors(c2)):
        return c1.count == c2.count && zip(c1, c2).lazy.map { $0.0 == $0.1 }.all()
    default:
        return false
    }
}

extension SequenceType where Generator.Element == Bool {
    func all() -> Bool {
        for elem in self {
            if !elem {
                return false
            }
        }
        return true
    }
}

protocol ValueKeeper {
    typealias ValueType

    var name: String { get }
    var inputValue: String? { get }
    var value: ValueType? { get }
    var errors: [ExtractError] { get }

    func required() throws -> ValueType
    func defaultValue(dv: ValueType) throws -> ValueType
}

extension ValueKeeper {
    func required() throws -> ValueType {
        if self.errors.count > 0 {
            throw ExtractError.CollectedErrors(self.errors)
        }
        if let v = self.value {
            return v
        }
        throw ExtractError.ValueMissing(name: self.name)
    }

    func defaultValue(dv: ValueType) throws -> ValueType {
        if self.errors.count > 0 {
            switch self.errors[0] {
            case .ValueMissing(_):
                break
            default:
                throw ExtractError.CollectedErrors(self.errors)
            }
        }
        if let v = self.value {
            return v
        }
        return dv
    }
}

struct ExtractedTypedValue<T>: ValueKeeper {
    let name: String
    let inputValue: String?
    let value: T?
    let errors: [ExtractError]

    init(name: String, inputValue: String?, value: T) {
        self.name = name
        self.inputValue = inputValue
        self.value = value
        self.errors = []
    }

    init(name: String, inputValue: String?, errors: [ExtractError]) {
        self.name = name
        self.inputValue = inputValue
        self.value = nil
        self.errors = errors
    }
}

extension ValueKeeper where ValueType == Int {
    func range(r: Range<Int>) -> ExtractedTypedValue<Int> {
        guard let val = self.value else {
            return ExtractedTypedValue(name: self.name, inputValue: self.inputValue, errors: self.errors)
        }

        if r.contains(val) {
            return ExtractedTypedValue(name: self.name, inputValue: self.inputValue, value: val)
        }

        let rangeErr = ExtractError.IntRangeError(name: self.name, value: val, range: r)
        var errors = self.errors
        errors.append(rangeErr)
        return ExtractedTypedValue(name: self.name, inputValue: self.inputValue, errors: errors)
    }
}


struct ExtractedString: ValueKeeper, CustomDebugStringConvertible {
    let name: String
    let inputValue: String?
    let parser: ValueParser
    let errors: [ExtractError] = []

    var value: String? {
        return self.inputValue
    }

    func asInt() throws -> ExtractedTypedValue<Int> {
        debugPrint("asInt: Enter", self)
        if let val = self.value {
            do {
                let ival = try self.parser.parseInt(self.name, value: val)
                debugPrint("asInt: Got ival", ival)
                return ExtractedTypedValue<Int>(name: self.name, inputValue: self.inputValue, value: ival)
            } catch let err as ExtractError {
                return ExtractedTypedValue<Int>(name: self.name, inputValue: self.inputValue, errors: [err])
            } catch {
                debugPrint("asInt: Failed to parse ival", error)
                return ExtractedTypedValue<Int>(name: self.name, inputValue: self.inputValue, errors: [ExtractError.fromError(error)])
            }
        }
        return ExtractedTypedValue<Int>(name: self.name, inputValue: self.inputValue, errors: [.ValueMissing(name: self.name)])
    }

    func asBool() throws -> ExtractedTypedValue<Bool> {
        if let val = self.value {
            let bval = (val as NSString).boolValue
            return ExtractedTypedValue<Bool>(name: self.name, inputValue: self.inputValue, value: bval)
        }
        return ExtractedTypedValue<Bool>(name: self.name, inputValue: self.inputValue, errors: [.ValueMissing(name: self.name)])
    }

    var debugDescription: String {
        return "ExtractedString name:\(self.name) inputValue:\(self.inputValue)"
    }

}

