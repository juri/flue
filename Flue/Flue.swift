//
//  Flue.swift
//  Flue
//
//  Created by Juri Pakaste on 09/02/16.
//  Copyright © 2016 Juri Pakaste. All rights reserved.
//

import Foundation

/**
 ValueParser is the starting point for extracting data from input.
 */
public class ValueParser {
    private let integerFormatter: NSNumberFormatter
    private let floatFormatter: NSNumberFormatter
    private let dateFormatter: NSDateFormatter

    /// Construct ValueParser for the given locale. Defaults to POSIX.
    public init(locale: NSLocale = NSLocale(localeIdentifier: "POSIX")) {
        let integerFormatter = NSNumberFormatter()
        integerFormatter.locale = locale
        integerFormatter.maximumFractionDigits = 0
        integerFormatter.allowsFloats = false
        self.integerFormatter = integerFormatter

        let floatFormatter = NSNumberFormatter()
        floatFormatter.locale = locale
        floatFormatter.maximumFractionDigits = 100
        self.floatFormatter = floatFormatter

        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = locale
        dateFormatter.timeStyle = .ShortStyle
        dateFormatter.dateStyle = .ShortStyle
        self.dateFormatter = dateFormatter
    }

    private func parseInt(name: String?, value: String) throws -> Int {
        guard let n = self.integerFormatter.numberFromString(value) as? Int else {
            throw ExtractError.FormatError(name: name, value: value, expectType: "Integer")
        }
        return n
    }

    private func parseDouble(name: String?, value: String) throws -> Double {
        guard let n = self.floatFormatter.numberFromString(value) as? Double else {
            throw ExtractError.FormatError(name: name, value: value, expectType: "Double")
        }
        return n
    }

    /// Returns an ExtractedString object that can be used to operate on the value.
    public func extract(value: String?, name: String? = nil) -> ExtractedString {
        return ExtractedString(name: name, inputValue: value, parser: self)
    }
}

/**
 DictParser extracts values from a [String: String] dictionary.
 */
public class DictParser {
    private let vp: ValueParser
    private let dict: [String: String]

    public init(dict: [String: String], valueParser: ValueParser = ValueParser()) {
        self.dict = dict
        self.vp = valueParser
    }

    public func extract(key: String) -> ExtractedString {
        return self.vp.extract(self.dict[key], name: key)
    }
}

/**
 ExtractError is an enum for the errors emitted by the built-in Flue functions.
 */
public enum ExtractError: ErrorType, CustomStringConvertible, Equatable {
    /// Flue returns ValueMissing when the parser received a nil value.
    case ValueMissing(name: String?)
    /// Flue returns FormatError when conversion to a different type fails.
    case FormatError(name: String?, value: String, expectType: String)
    /// Flue returns IntRangeError when `range` fails on an integer value.
    case IntRangeError(name: String?, value: Int, range: Range<Int>)
    case ValueTooSmallError(name: String?, value: String, shouldBeGreaterThan: String)
    case ValueTooLargeError(name: String?, value: String, shouldBeLessThan: String)
    /// Flue returns StringMinLengthError when `minLength` fails on a string value.
    case StringMinLengthError(name: String?, value: String, minLength: Int)
    /// Flue returns StringMaxLengthError when `maxLength` fails on a string value.
    case StringMaxLengthError(name: String?, value: String, maxLength: Int)
    /// Flue returns RegexpError when `regexp` fails on a string value.
    case RegexpError(name: String?, value: String, regexp: String)
    /// Flue returns DateFormatError when `value` couldn't be parsed as a NSDate with `format`.
    case DateFormatError(name: String?, value: String, format: String)
    /// Flue returns DateTooEarlyError when `value` represented a date that was earlier than `limit`.
    case DateTooEarlyError(name: String?, value: NSString, limit: NSString)
    /// Flue returns DateTooLateError when `value` represented a date that was later than `limit`.
    case DateTooLateError(name: String?, value: NSString, limit: NSString)
    /// Flue returns OtherError when an unexpected error occurs.
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
        case let .ValueTooLargeError(name, value, limit):
            if let n = name {
                return "Key \(n) had value \(value), must be smaller than \(limit)"
            } else {
                return "Value \(value) not smaller than \(limit)"
            }
        case let .ValueTooSmallError(name, value, limit):
            if let n = name {
                return "Key \(n) had value \(value), must be larger than \(limit)"
            } else {
                return "Value \(value) not larger than \(limit)"
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
        case let .DateFormatError(name, value, format):
            if let n = name {
                return "Key \(n) had value \(value) that couldn't be parsed as date with format \(format)"
            }
            return "Value \(value) couldn't be parsed as date with format \(format)"
        case let .DateTooEarlyError(name, value, limit):
            if let n = name {
                return "Key \(n) had value \(value), must be after \(limit)"
            }
            return "Date was \(value), must be after \(limit)"
        case let .DateTooLateError(name, value, limit):
            if let n = name {
                return "Key \(n) had value \(value), must be before \(limit)"
            }
            return "Date was \(value), must be before \(limit)"
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

/**
 ConversionResult is a Success/Failure result enum for conversions.
 */
public enum ConversionResult<T, Error: ErrorType> {
    case Success(T)
    case Failure(Error)
}

/**
 OriginalValue keeps the originally extracted value.
 */
public struct OriginalValue {
    let name: String?
    let value: String?
}

/**
 ConversionContext keeps the originally extracted value and the latest conversion result.
 */
public struct ConversionContext {
    internal let valueParser: ValueParser
    let originalValue: OriginalValue
}

/**
 ConversionStep is one step in a chain of conversions or validations.
 
 It's parametrized with three functions that provide the value handling logic:

 - `input` reads the value from previous step.
 - `convert` converts the value from `input` to the next type.
 - `help` returns the current array of help messages.
 */
public struct ConversionStep<Input, Output>: ConversionStepProtocol {
    public let input: () -> ConversionResult<Input, ExtractError>
    public let convert: (Input, ConversionContext) -> ConversionResult<Output, ExtractError>
    public let help: (ConversionContext) -> [String]
    public let context: ConversionContext

    /// Returns a `ConversionContext` containing either the value from `input` processed through `convert` or the error it contained.
    public func readValue() -> ConversionResult<Output, ExtractError> {
        let res = self.input()
        switch res {
        case .Success(let v): return self.convert(v, self.context)
        case .Failure(let e): return .Failure(e)
        }
    }

    /// Returns the success value from `readValue` or throws the error.
    ///
    /// - Throws: The error contained in the `ConversionContext` returned by `readValue`.
    public func required() throws -> Output {
        switch self.readValue() {
        case .Success(let v): return v
        case .Failure(let e): throw e
        }
    }

    /// Returns the success value from `readValue` or the default value given as parameter.
    ///
    /// - Parameter v: default value to return if `readValue`'s return value contained an error.
    public func defaultValue(v: Output) -> Output {
        switch self.readValue() {
        case .Success(let v): return v
        case .Failure(_): return v
        }
    }

    /// Returns an optional containing the success value from `readValue` or nil.
    public func optional() -> Output? {
        switch self.readValue() {
        case .Success(let v): return v
        case .Failure(_): return nil
        }
    }

    /// Returns the collected help array from `help` with an additional usage string.
    ///
    /// - Parameter s: Extra usage information string.
    /// - Parameter prefix: If `true`, usage string will be the first element of the returned array.
    ///   Otherwise it'll be the last element. Defaults to `false`.
    public func usage(s: String? = nil, prefix: Bool = false) -> [String] {
        guard let ss = s else {
            return self.help(self.context)
        }
        if prefix {
            return [ss] + self.help(self.context)
        }
        return self.help(self.context) + [ss]
    }
}

/**
 Helper protocol for `ConversionStep` for adding type specific extension methods.
 */
public protocol ConversionStepProtocol {
    associatedtype Input
    associatedtype Output

    var input: () -> ConversionResult<Input, ExtractError> { get }
    var convert: (Input, ConversionContext) -> ConversionResult<Output, ExtractError> { get }
    var help: (ConversionContext) -> [String] { get }
    var context: ConversionContext { get }
    func readValue() -> ConversionResult<Output, ExtractError>
}

public extension ConversionStepProtocol {
    /**
     Creates a step that converts the input value to a new type, as specified by the function in the `convert` parameter.

     - Parameter convert: A function that can be used as the `convert` value in a `ConversionStep`.
     - Parameter help: A string to use as the help string for this step. If nil, it will default to a string describing the type returned by `convert`.
     */
    public func asType<NewType>(convert: ((Output, ConversionContext) -> ConversionResult<NewType, ExtractError>), help: String? = nil) -> ConversionStep<Output,NewType> {
        func helpFunc(ctx: ConversionContext) -> [String] {
            if let h = help {
                return self.help(ctx) + [h]
            } else {
                return self.help(ctx) + ["Type: \(NewType.self)"]
            }
        }
        return ConversionStep(input: self.readValue, convert: convert, help: helpFunc, context: self.context)
    }

    /**
     Creates a step that converts the input value to a new type, as specified by the function in the `convert` parameter.
     This variant takes a function that returns an optional, instead of a `ConversionResult`.

     - Parameter convert: A function returning an optional value of the new type. It will be wrapped in a function that returns an `ExtractError.FormatError` in case of nil and that new function will be used as the `convert` value in a `ConversionStep`.
     - Parameter help: A string to use as the help string for this step. If nil, it will default to a string describing the type returned by `convert`.
     */
    public func asType<NewType>(convert: ((Output, ConversionContext) -> NewType?), help: String? = nil) -> ConversionStep<Output,NewType> {
        func cwrap(v: Output, ctx: ConversionContext) -> ConversionResult<NewType, ExtractError> {
            if let cv = convert(v, ctx) {
                return .Success(cv)
            }
            return .Failure(ExtractError.FormatError(name: ctx.originalValue.name, value: ctx.originalValue.value ?? "", expectType: "\(NewType.self)"))
        }
        return self.asType(cwrap, help: help)
    }
}

extension ConversionStepProtocol where Output == Int {
    /**
     Creates a `ConversionStep` that checks that the input integer is in the specified range.
     The `ConversionStep` will return a `ExtractError.IntRangeError` if the range
     does not contain the input value.
     
     - Parameter r: The range the input value should be in.
     */
    func range(r: Range<Int>) -> ConversionStep<Int, Int> {
        func convert(i: Int, ctx: ConversionContext) -> ConversionResult<Int, ExtractError> {
            if r.contains(i) {
                return .Success(i)
            }
            return .Failure(ExtractError.IntRangeError(name: ctx.originalValue.name, value: i, range: r))
        }
        func help(ctx: ConversionContext) -> [String] {
            return self.help(ctx) + ["Range: \(r)"]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }
}

extension ConversionStepProtocol where Output == String {
    /**
     Creates a `ConversionStep` that checks that the input string is at least `l` characters long.
     The `ConversionStep` will return a `ExtractError.StringMinLengthError` if it the string is shorter.

     - Parameter l: The minimum length for the string.
     */
    func minLength(l: Int) -> ConversionStep<String, String> {
        func convert(s: String, ctx: ConversionContext) -> ConversionResult<String, ExtractError> {
            if s.characters.count >= l {
                return .Success(s)
            }
            return .Failure(ExtractError.StringMinLengthError(name: ctx.originalValue.name, value: s, minLength: l))
        }
        func help(ctx: ConversionContext) -> [String] {
            return self.help(ctx) + ["Minimum length: \(ctx.valueParser.integerFormatter.stringFromNumber(l)!)"]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    /**
     Creates a `ConversionStep` that checks that the input string is at most `l` characters long.
     The `ConversionStep` will return a `ExtractError.StringMaxLengthError` if the string is longer.

     - Parameter l: The maximum length for the string.
     */
    func maxLength(l: Int) -> ConversionStep<String, String> {
        func convert(s: String, ctx: ConversionContext) -> ConversionResult<String, ExtractError> {
            if s.characters.count <= l {
                return .Success(s)
            }
            return .Failure(ExtractError.StringMaxLengthError(name: ctx.originalValue.name, value: s, maxLength: l))
        }
        func help(ctx: ConversionContext) -> [String] {
            return self.help(ctx) + ["Maximum length: \(ctx.valueParser.integerFormatter.stringFromNumber(l)!)"]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }
}

extension ConversionStepProtocol where Output == Double {
    /**
     Creates a `ConversionStep` that checks that the input double is greater than `limit`.
     
     - Parameter limit: The lower non-inclusive bound for the value.
     */
    func greaterThan(limit: Double) -> ConversionStep<Double, Double> {
        func convert(d: Double, ctx: ConversionContext) -> ConversionResult<Double, ExtractError> {
            if d > limit {
                return .Success(d)
            }
            return .Failure(ExtractError.ValueTooSmallError(
                name: ctx.originalValue.name,
                value: ctx.originalValue.value!,
                shouldBeGreaterThan: ctx.valueParser.floatFormatter.stringFromNumber(limit)!))
        }
        func help(ctx: ConversionContext) -> [String] {
            return self.help(ctx) + ["Must be greater than: \(ctx.valueParser.floatFormatter.stringFromNumber(limit)!)"]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    /**
     Creates a `ConversionStep` that checks that the input double is less than `limit`.

     - Parameter limit: The upper non-inclusive bound for the value.
     */
    func lessThan(limit: Double) -> ConversionStep<Double, Double> {
        func convert(d: Double, ctx: ConversionContext) -> ConversionResult<Double, ExtractError> {
            if d < limit {
                return .Success(d)
            }
            return .Failure(ExtractError.ValueTooLargeError(
                name: ctx.originalValue.name,
                value: ctx.originalValue.value!,
                shouldBeLessThan: ctx.valueParser.floatFormatter.stringFromNumber(limit)!))
        }
        func help(ctx: ConversionContext) -> [String] {
            return self.help(ctx) + ["Must be less than: \(ctx.valueParser.floatFormatter.stringFromNumber(limit)!)"]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }
}

extension ConversionStepProtocol where Output == NSDate {
    func before(limit: NSDate) -> ConversionStep<NSDate, NSDate> {
        func convert(d: NSDate, ctx: ConversionContext) -> ConversionResult<NSDate, ExtractError> {
            if d.earlierDate(limit) == d {
                return .Success(d)
            }
            return .Failure(ExtractError.DateTooLateError(
                name: ctx.originalValue.name,
                value: ctx.originalValue.value!,
                limit: ctx.valueParser.dateFormatter.stringFromDate(limit)))
        }
        func help(ctx: ConversionContext) -> [String] {
            return self.help(ctx) + ["Must be before \(ctx.valueParser.dateFormatter.stringFromDate(limit))"]
        }

        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    func after(limit: NSDate) -> ConversionStep<NSDate, NSDate> {
        func convert(d: NSDate, ctx: ConversionContext) -> ConversionResult<NSDate, ExtractError> {
            if d.laterDate(limit) == d {
                return .Success(d)
            }
            return .Failure(ExtractError.DateTooEarlyError(
                name: ctx.originalValue.name,
                value: ctx.originalValue.value!,
                limit: ctx.valueParser.dateFormatter.stringFromDate(limit)))
        }
        func help(ctx: ConversionContext) -> [String] {
            return self.help(ctx) + ["Must be after \(ctx.valueParser.dateFormatter.stringFromDate(limit))"]
        }

        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }
}

/**
 ExtractedString is the initially extracted value.
 */
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

    func inputForReader() -> ConversionResult<String, ExtractError> {
        guard let val = self.inputValue else {
            return .Failure(.ValueMissing(name: self.name))
        }
        return .Success(val)
    }

    /// Creates a `ConversionStep` that just treats the value as a String.
    public func asString() -> ConversionStep<String, String> {
        func convert(s: String, ctx: ConversionContext) -> ConversionResult<String, ExtractError> {
            return .Success(s)
        }
        func help(ctx: ConversionContext) -> [String] {
            return self.help("String")
        }
        return ConversionStep(input: self.inputForReader, convert: convert, help: help, context: self.conversionContext)
    }

    /// Creates a `ConversionStep` that parses the input string as an integer, using the locale initially passed in to the `ValueParser` constructor.
    /// The `ConversionStep` will return a `ExtractError.FormatError` if parsing fails.
    public func asInt() -> ConversionStep<String, Int> {
        func convert(s: String, ctx: ConversionContext) -> ConversionResult<Int, ExtractError> {
            do {
                let parsed = try self.parser.parseInt(ctx.originalValue.name, value: s)
                return .Success(parsed)
            } catch let err as ExtractError {
                return .Failure(err)
            } catch {
                return .Failure(ExtractError.fromError(error))
            }
        }
        func help(ctx: ConversionContext) -> [String] {
            return self.help("Integer")
        }

        return ConversionStep(input: self.inputForReader, convert: convert, help: help, context: self.conversionContext)
    }

    /// Creates a `ConversionStep` that parses the input string as a double, using the locale initially passed in to the `ValueParser` constructor.
    /// The `ConversionStep` will return a `ExtractError.FormatError` if parsing fails.
    public func asDouble() -> ConversionStep<String, Double> {
        func convert(s: String, ctx: ConversionContext) -> ConversionResult<Double, ExtractError> {
            do {
                let parsed = try self.parser.parseDouble(ctx.originalValue.name, value: s)
                return .Success(parsed)
            } catch let err as ExtractError {
                return .Failure(err)
            } catch {
                return .Failure(ExtractError.fromError(error))
            }
        }
        func help(ctx: ConversionContext) -> [String] {
            return self.help("Integer")
        }

        return ConversionStep(input: self.inputForReader, convert: convert, help: help, context: self.conversionContext)
    }

    /// Creates a `ConversionStep` that parses the input string as a boolean, using `NSString`'s `boolValue` method.
    public func asBool() -> ConversionStep<String, Bool> {
        func convert(s: String, ctx: ConversionContext) -> ConversionResult<Bool, ExtractError> {
            let bval = (s as NSString).boolValue
            return .Success(bval)
        }

        func help(ctx: ConversionContext) -> [String] {
            return self.help("True if string starts with [YyTt1-9]")
        }

        return ConversionStep(input: self.inputForReader, convert: convert, help: help, context: self.conversionContext)
    }

    public func asDate(df: NSDateFormatter) -> ConversionStep<String, NSDate> {
        func convert(s: String, ctx: ConversionContext) -> ConversionResult<NSDate, ExtractError> {
            if let parsed = df.dateFromString(s) {
                return .Success(parsed)
            }
            return .Failure(ExtractError.DateFormatError(name: ctx.originalValue.name, value: s, format: df.dateFormat))
        }

        func help(ctx: ConversionContext) -> [String] {
            return self.help("Date with format \(df.dateFormat)")
        }

        return ConversionStep(input: self.inputForReader, convert: convert, help: help, context: self.conversionContext)
    }

    internal var originalValue: OriginalValue {
        return OriginalValue(name: self.name, value: self.inputValue)
    }

    internal var conversionContext: ConversionContext {
        return ConversionContext(valueParser: self.parser, originalValue: self.originalValue)
    }
}
