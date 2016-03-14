//
//  Env.swift
//  Flue
//
//  Created by Juri Pakaste on 09/02/16.
//  Copyright © 2016 Juri Pakaste. All rights reserved.
//

import Foundation

public class ValueParser {
    private let integerFormatter: NSNumberFormatter

    public init(locale: NSLocale = NSLocale(localeIdentifier: "POSIX")) {
        let integerFormatter = NSNumberFormatter()
        integerFormatter.locale = locale
        integerFormatter.maximumFractionDigits = 0
        self.integerFormatter = integerFormatter
    }

    private func parseInt(name: String?, value: String) throws -> Int {
        guard let n = self.integerFormatter.numberFromString(value) as? Int else {
            throw ExtractError.FormatError(name: name, value: value, expectType: "Integer")
        }
        return n
    }

    public func extract(name: String?, value: String?) -> ExtractedString {
        return ExtractedString(name: name, inputValue: value, parser: self)
    }
}

public class DictParser {
    private let vp: ValueParser
    private let dict: [String: String]

    public init(dict: [String: String], valueParser: ValueParser = ValueParser()) {
        self.dict = dict
        self.vp = valueParser
    }

    public func extract(key: String) -> ExtractedString {
        return self.vp.extract(key, value: self.dict[key])
    }
}

public enum ExtractError: ErrorType, CustomStringConvertible, Equatable {
    case ValueMissing(name: String?)
    case FormatError(name: String?, value: String, expectType: String)
    case IntRangeError(name: String?, value: Int, range: Range<Int>)
    case StringMinLengthError(name: String?, value: String, minLength: Int)
    case StringMaxLengthError(name: String?, value: String, maxLength: Int)
    case RegexpError(name: String?, value: String, regexp: String)
    case OtherError(String)

    public var description: String {
        switch self {
        case .ValueMissing(let name):
            if let n = name {
                return "Required value \(n) wasn't found"
            } else {
                return "Required value wasn't found"
            }
        case .FormatError(let name, let value, let expectType):
            if let n = name {
                return "Key \"\(n)\" format error. Had value \(value), not \(expectType)"
            } else {
                return "Format error. Had value \(value), not \(expectType)"
            }
        case let .IntRangeError(name, value, range):
            if let n = name {
                return "Key \(n) had value \(value), not in range \(range)"
            } else {
                return "Value \(value) not in range \(range)"
            }
        case let .StringMinLengthError(name, value, minLength):
            if let n = name {
                return "Key \(n) had value \(value), shorter than minimum length \(minLength)"
            } else {
                return "Value \(value) is shorter than minimum length \(minLength)"
            }
        case let .StringMaxLengthError(name, value, maxLength):
            if let n = name {
                return "Key \(n) had value \(value), longer than minimum length \(maxLength)"
            } else {
                return "Value \(value) is longer than minimum length \(maxLength)"
            }
        case let .RegexpError(name, value, regexp):
            if let n = name {
                return "Key \(n) had value \(value) that didn't match regular expression \(regexp)"
            } else {
                return "Value \(value) didn't match regular expression \(regexp)"
            }
        case .OtherError(let msg):
            return msg
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

public func ==(ee1: ExtractError, ee2: ExtractError) -> Bool {
    switch (ee1, ee2) {
    case let (.ValueMissing(n1), .ValueMissing(n2)):
        return n1 == n2
    case let (.FormatError(name1, value1, expectType1), .FormatError(name2, value2, expectType2)):
        return name1 == name2 && value1 == value2 && expectType1 == expectType2
    case let (.IntRangeError(name1, value1, range1), .IntRangeError(name2, value2, range2)):
        return name1 == name2 && value1 == value2 && range1 == range2
    case let (.StringMinLengthError(name1, value1, l1), .StringMinLengthError(name2, value2, l2)):
        return name1 == name2 && value1 == value2 && l1 == l2
    case let (.StringMaxLengthError(name1, value1, l1), .StringMaxLengthError(name2, value2, l2)):
        return name1 == name2 && value1 == value2 && l1 == l2
    case let (.OtherError(v1), .OtherError(v2)):
        return v1 == v2
    case let (.RegexpError(n1, v1, r1), .RegexpError(n2, v2, r2)):
        return n1 == n2 && v1 == v2 && r1 == r2
    default:
        return false
    }
}

public enum ConversionResult<T, Error: ErrorType> {
    case Success(T)
    case Failure(Error)
}

public struct OriginalValue {
    let name: String?
    let value: String?
}

public struct ConversionContext<T, Error: ErrorType> {
    private let originalValue: OriginalValue
    let result: ConversionResult<T, Error>
}

public struct ConversionStep<Input, Output>: ConversionStepProtocol {
    public let input: () -> ConversionContext<Input, ExtractError>
    public let convert: (Input, OriginalValue) -> ConversionResult<Output, ExtractError>
    public let help: () -> [String]

    public func readValue() -> ConversionContext<Output, ExtractError> {
        let cc = self.input()
        switch cc.result {
        case .Success(let v): return ConversionContext(originalValue: cc.originalValue, result: self.convert(v, cc.originalValue))
        case .Failure(let e): return ConversionContext(originalValue: cc.originalValue, result: .Failure(e))
        }
    }

    public func required() throws -> Output {
        let cc = self.readValue()
        switch cc.result {
        case .Success(let v): return v
        case .Failure(let e): throw e
        }
    }

    public func defaultValue(v: Output) -> Output {
        let cc = self.readValue()
        switch cc.result {
        case .Success(let v): return v
        case .Failure(_): return v
        }
    }

    public func optional() -> Output? {
        let cc = self.readValue()
        switch cc.result {
        case .Success(let v): return v
        case .Failure(_): return nil
        }
    }

    public func usage(s: String, prefix: Bool = false) -> [String] {
        if prefix {
            return [s] + self.help()
        }
        return self.help() + [s]
    }
}

public protocol ConversionStepProtocol {
    associatedtype Input
    associatedtype Output

    var input: () -> ConversionContext<Input, ExtractError> { get }
    var convert: (Input, OriginalValue) -> ConversionResult<Output, ExtractError> { get }
    var help: () -> [String] { get }
    func readValue() -> ConversionContext<Output, ExtractError>
}

public extension ConversionStepProtocol {
    public func asType<NewType>(convert: ((Output, OriginalValue) -> ConversionResult<NewType, ExtractError>), help: String? = nil) -> ConversionStep<Output,NewType> {
        func input() -> ConversionContext<Output, ExtractError> {
            return self.readValue()
        }
        func helpFunc() -> [String] {
            if let h = help {
                return self.help() + [h]
            } else {
                return self.help() + ["Type: \(NewType.self)"]
            }
        }
        return ConversionStep(input: input, convert: convert, help: helpFunc)
    }

    public func asType<NewType>(convert: ((Output, OriginalValue) -> NewType?), help: String? = nil) -> ConversionStep<Output,NewType> {
        func cwrap(v: Output, ov: OriginalValue) -> ConversionResult<NewType, ExtractError> {
            if let cv = convert(v, ov) {
                return .Success(cv)
            }
            return .Failure(ExtractError.FormatError(name: ov.name, value: ov.value ?? "", expectType: "\(NewType.self)"))
        }
        return self.asType(cwrap, help: help)
    }
}

extension ConversionStepProtocol where Output == Int {
    func range(r: Range<Int>) -> ConversionStep<Int, Int> {
        func input() -> ConversionContext<Int, ExtractError> {
            return self.readValue()
        }
        func convert(i: Int, ov: OriginalValue) -> ConversionResult<Int, ExtractError> {
            if r.contains(i) {
                return .Success(i)
            }
            return .Failure(ExtractError.IntRangeError(name: ov.name, value: i, range: r))
        }
        func help() -> [String] {
            return self.help() + ["Range: \(r)"]
        }
        return ConversionStep(input: input, convert: convert, help: help)
    }
}

extension ConversionStepProtocol where Output == String {
    func minLength(l: Int) -> ConversionStep<String, String> {
        func convert(s: String, ov: OriginalValue) -> ConversionResult<String, ExtractError> {
            if s.characters.count >= l {
                return .Success(s)
            }
            return .Failure(ExtractError.StringMinLengthError(name: ov.name, value: s, minLength: l))
        }
        func help() -> [String] {
            return self.help() + ["Minimum length: \(l)"]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help)
    }

    func maxLength(l: Int) -> ConversionStep<String, String> {
        func convert(s: String, ov: OriginalValue) -> ConversionResult<String, ExtractError> {
            if s.characters.count <= l {
                return .Success(s)
            }
            return .Failure(ExtractError.StringMaxLengthError(name: ov.name, value: s, maxLength: l))
        }
        func help() -> [String] {
            return self.help() + ["Maximum length: \(l)"]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help)
    }
}

public struct ExtractedString: CustomDebugStringConvertible {
    let name: String?
    let inputValue: String?
    let parser: ValueParser

    var value: String? {
        return self.inputValue
    }

    public var debugDescription: String {
        return "ExtractedString name:\(self.name) inputValue:\(self.inputValue)"
    }

    func help(extra: String) -> [String] {
        if let name = self.name {
            return ["Name: \(name)", extra]
        }
        return [extra]
    }

    func inputForReader() -> ConversionContext<String, ExtractError> {
        let original = OriginalValue(name: self.name, value: self.inputValue)
        guard let val = self.inputValue else {
            return ConversionContext(originalValue: original, result: .Failure(.ValueMissing(name: self.name)))
        }
        return ConversionContext(originalValue: original, result: .Success(val))
    }

    public func asString() -> ConversionStep<String, String> {
        func convert(s: String, ov: OriginalValue) -> ConversionResult<String, ExtractError> {
            return .Success(s)
        }
        func help() -> [String] {
            return self.help("String")
        }
        return ConversionStep(input: self.inputForReader, convert: convert, help: help)
    }

    public func asInt() -> ConversionStep<String, Int> {
        func convert(s: String, ov: OriginalValue) -> ConversionResult<Int, ExtractError> {
            do {
                let parsed = try self.parser.parseInt(ov.name, value: s)
                return .Success(parsed)
            } catch let err as ExtractError {
                return .Failure(err)
            } catch {
                return .Failure(ExtractError.fromError(error))
            }
        }
        func help() -> [String] {
            return self.help("Integer")
        }

        return ConversionStep(input: self.inputForReader, convert: convert, help: help)
    }

    public func asBool() -> ConversionStep<String, Bool> {
        func convert(s: String, ov: OriginalValue) -> ConversionResult<Bool, ExtractError> {
            let bval = (s as NSString).boolValue
            return .Success(bval)
        }

        func help() -> [String] {
            return self.help("True if string starts with [YyTt1-9]")
        }

        return ConversionStep(input: self.inputForReader, convert: convert, help: help)
    }
}
