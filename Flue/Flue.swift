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

    /// Construct ValueParser for the given locale. Defaults to en_US_POSIX.
    public init(locale: NSLocale = NSLocale(localeIdentifier: "en_US_POSIX")) {
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

    /// Returns an ExtractedString object that can be used to operate on the value.
    public func extract(value: String?, name: String? = nil) -> ExtractedString {
        return ExtractedString(name: name, inputValue: value, parser: self)
    }
}

/**
 DictParser extracts values from a [String: String] dictionary.
 */
public class DictParser {
    private let dict: [String: String]
    public let vp: ValueParser

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
    /// Flue returns BadFormat when conversion to a different type fails.
    case BadFormat(name: String?, value: String, expectType: String)
    /// Flue returns IntNotInRange when `range` fails on an integer value.
    case IntNotInRange(name: String?, value: Int, range: Range<Int>)
    case ValueTooSmall(name: String?, value: String, shouldBeGreaterThan: String)
    case ValueTooLarge(name: String?, value: String, shouldBeLessThan: String)
    /// Flue returns StringTooShort when `minLength` fails on a string value.
    case StringTooShort(name: String?, value: String, minLength: Int)
    /// Flue returns StringTooLong when `maxLength` fails on a string value.
    case StringTooLong(name: String?, value: String, maxLength: Int)
    /// Flue returns NoRegexpMatch when `regexp` fails on a string value.
    case NoRegexpMatch(name: String?, value: String, regexp: String)
    /// Flue returns DateBadFormat when `value` couldn't be parsed as a NSDate with `format`.
    case DateBadFormat(name: String?, value: String, format: String)
    /// Flue returns DateTooEarly when `value` represented a date that was earlier than `limit`.
    case DateTooEarly(name: String?, value: NSString, limit: NSString)
    /// Flue returns DateTooLate when `value` represented a date that was later than `limit`.
    case DateTooLate(name: String?, value: NSString, limit: NSString)
    /// Flue returns OtherError when an unexpected error occurs.
    case OtherError(String)

    public func descriptionWithValueParser(vp: ValueParser) -> String {
        switch self {
        case .ValueMissing(let name):
            if let n = name {
                return String(format: 
                    NSLocalizedString("Flue.Error.ValueMissing.Named", bundle: flueBundle(), comment: "Flue: ValueMissing error, named. Parameters: name"),
                    n)
            }
            return NSLocalizedString("Flue.Error.ValueMissing.Anonymous", bundle: flueBundle(), comment: "Flue: ValueMissing error, no name")

        case .BadFormat(let name, let value, let expectType):
            if let n = name {
                return String(format: 
                    NSLocalizedString("Flue.Error.BadFormat.Named", bundle: flueBundle(), comment: "Flue: Format error, named. Parameters: name, value, expected type"),
                    n, value, expectType)
            }
            return String(format: 
                NSLocalizedString("Flue.Error.BadFormat.Anonymous", bundle: flueBundle(), comment: "Flue: Format error, no name. Parameters: value, expected type"),
                value, expectType)

        case let .IntNotInRange(name, value, range):
            if let n = name {
                return String(format: 
                    NSLocalizedString("Flue.Error.IntNotInRange.Named", bundle: flueBundle(), comment: "Flue: IntRange error, named. Parameters: name, value, range"),
                    n, vp.integerFormatter.stringFromNumber(value)!, range.description)
            }
            return String(format: 
                NSLocalizedString("Flue.Error.IntNotInRange.Anonymous", bundle: flueBundle(), comment: "Flue: IntRange error, no name. Parameters: value, range"),
                vp.integerFormatter.stringFromNumber(value)!, range.description)

        case let .ValueTooLarge(name, value, limit):
            if let n = name {
                return String(format: 
                    NSLocalizedString("Flue.Error.ValueTooLarge.Named", bundle: flueBundle(), comment: "Flue: ValueTooLarge error, named. Parameters: name, value, limit"),
                    n, value, limit)
            }
            return String(format: 
                NSLocalizedString("Flue.Error.ValueTooLarge.Anonoymous", bundle: flueBundle(), comment: "Flue: ValueTooLarge error, no name. Parameters: value, limit"),
                value, limit)

        case let .ValueTooSmall(name, value, limit):
            if let n = name {
                return String(format: 
                    NSLocalizedString("Flue.Error.ValueTooSmall.Named", bundle: flueBundle(), comment: "Flue: ValueTooSmall error, named. Parameters: name, value, limit"),
                    n, value, limit)

            }
            return String(format: 
                NSLocalizedString("Flue.Error.ValueTooSmall.Anonymous", bundle: flueBundle(), comment: "Flue: ValueTooSmall error, no name. Parameters: value, limit"),
                value, limit)

        case let .StringTooShort(name, value, minLength):
            if let n = name {
                return String(format: 
                    NSLocalizedString("Flue.Error.StringTooShort.Named", bundle: flueBundle(), comment: "Flue: StringMinLength error, named. Parameters: name, value, min length"),
                    n, value, vp.integerFormatter.stringFromNumber(minLength)!)
            }
            return String(format: 
                NSLocalizedString("Flue.Error.StringTooShort.Anonymous", bundle: flueBundle(), comment: "Flue: StringMinLength error, no name. Parameters: value, min length"),
                value, vp.integerFormatter.stringFromNumber(minLength)!)

        case let .StringTooLong(name, value, maxLength):
            if let n = name {
                return String(format: 
                    NSLocalizedString("Flue.Error.StringTooLong.Named", bundle: flueBundle(), comment: "Flue: StringMaxLength error, named. Parameters: name, value, max length"),
                    n, value, vp.integerFormatter.stringFromNumber(maxLength)!)
            }
            return String(format: 
                NSLocalizedString("Flue.Error.StringTooLong.Anonymous", bundle: flueBundle(), comment: "Flue: StringMaxLength error, no name. Parameters: value, max length"),
                value, vp.integerFormatter.stringFromNumber(maxLength)!)

        case let .NoRegexpMatch(name, value, regexp):
            if let n = name {
                return String(format: 
                    NSLocalizedString("Flue.Error.NoRegexpMatch.Named", bundle: flueBundle(), comment: "Flue: Regexp error, named: Parameters: name, value, regexp"),
                    n, value, regexp)
            }
            return String(format: 
                NSLocalizedString("Flue.Error.NoRegexpMatch.Anonymous", bundle: flueBundle(), comment: "Flue: Regexp error, no name: Parameters: value, regexp"),
                value, regexp)

        case let .DateBadFormat(name, value, format):
            if let n = name {
                return String(format: 
                    NSLocalizedString("Flue.Error.DateBadFormat.Named", bundle: flueBundle(), comment: "Flue: DateFormat error, named. Parameters: name, value, format"),
                    n, value, format)
            }
            return String(format: 
                NSLocalizedString("Flue.Error.DateBadFormat.Anonymous", bundle: flueBundle(), comment: "Flue: DateFormat error, no name. Parameters: value, format"),
                value, format)

        case let .DateTooEarly(name, value, limit):
            if let n = name {
                return String(format: 
                    NSLocalizedString("Flue.Error.DateTooEarly.Named", bundle: flueBundle(), comment: "Flue: DateTooEarly error, named. Parameters: name, value, limit"),
                    n, value, limit)
            }
            return String(format: 
                NSLocalizedString("Flue.Error.DateTooEarly.Anonymous", bundle: flueBundle(), comment: "Flue: DateTooEarly error, no name. Parameters: value, limit"),
                value, limit)
        case let .DateTooLate(name, value, limit):
            if let n = name {
                return String(format: 
                    NSLocalizedString("Flue.Error.DateTooLate.Named", bundle: flueBundle(), comment: "Flue: DateTooLate error, named. Parameters: name, value, limit"),
                    n, value, limit)
            }
            return String(format: 
                NSLocalizedString("Flue.Error.DateTooLate.Anonymous", bundle: flueBundle(), comment: "Flue: DateTooLate error, no name. Parameters: name, value, limit"),
                value, limit)

        case .OtherError(let msg):
            return msg
        }
    }

    public var description: String {
        return self.descriptionWithValueParser(ValueParser())
    }

    static func fromError(e: ErrorType) -> ExtractError {
        let errorDesc: String
        if let ep = e as? CustomStringConvertible {
            errorDesc = ep.description
        } else {
            errorDesc = NSLocalizedString("Flue.Error.UnknownError", bundle: flueBundle(), comment: "Flue: Wrapping an unexpected error that's not CustomStringConvertible")
        }
        return .OtherError(errorDesc)
    }
}

public func ==(ee1: ExtractError, ee2: ExtractError) -> Bool {
    switch (ee1, ee2) {
    case let (.ValueMissing(n1), .ValueMissing(n2)):
        return n1 == n2
    case let (.BadFormat(name1, value1, expectType1), .BadFormat(name2, value2, expectType2)):
        return name1 == name2 && value1 == value2 && expectType1 == expectType2
    case let (.IntNotInRange(name1, value1, range1), .IntNotInRange(name2, value2, range2)):
        return name1 == name2 && value1 == value2 && range1 == range2
    case let (.StringTooShort(name1, value1, l1), .StringTooShort(name2, value2, l2)):
        return name1 == name2 && value1 == value2 && l1 == l2
    case let (.StringTooLong(name1, value1, l1), .StringTooLong(name2, value2, l2)):
        return name1 == name2 && value1 == value2 && l1 == l2
    case let (.OtherError(v1), .OtherError(v2)):
        return v1 == v2
    case let (.NoRegexpMatch(n1, v1, r1), .NoRegexpMatch(n2, v2, r2)):
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

     - Parameter convert: A function returning an optional value of the new type. It will be wrapped in a function that returns an `ExtractError.BadFormat` in case of nil and that new function will be used as the `convert` value in a `ConversionStep`.
     - Parameter help: A string to use as the help string for this step. If nil, it will default to a string describing the type returned by `convert`.
     */
    public func asType<NewType>(convert: ((Output, ConversionContext) -> NewType?), help: String? = nil) -> ConversionStep<Output,NewType> {
        func cwrap(v: Output, ctx: ConversionContext) -> ConversionResult<NewType, ExtractError> {
            if let cv = convert(v, ctx) {
                return .Success(cv)
            }
            return .Failure(ExtractError.BadFormat(name: ctx.originalValue.name, value: ctx.originalValue.value ?? "", expectType: "\(NewType.self)"))
        }
        return self.asType(cwrap, help: help)
    }
}

extension ConversionStepProtocol where Output == Int {
    /**
     Creates a `ConversionStep` that checks that the input integer is in the specified range.
     The `ConversionStep` will return a `ExtractError.IntNotInRange` if the range
     does not contain the input value.
     
     - Parameter r: The range the input value should be in.
     */
    func range(r: Range<Int>) -> ConversionStep<Int, Int> {
        func convert(i: Int, ctx: ConversionContext) -> ConversionResult<Int, ExtractError> {
            if r.contains(i) {
                return .Success(i)
            }
            return .Failure(ExtractError.IntNotInRange(name: ctx.originalValue.name, value: i, range: r))
        }
        func help(ctx: ConversionContext) -> [String] {
            let msg = String(format: NSLocalizedString("Flue.Checks.Int.Range.Help", bundle: flueBundle(), comment: "Flue: Check int range: Help text. Parameters: Range"), r.description)
            return self.help(ctx) + [msg]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }
}

extension ConversionStepProtocol where Output == String {
    /**
     Creates a `ConversionStep` that checks that the input string is at least `l` characters long.
     The `ConversionStep` will return a `ExtractError.StringTooShort` if it the string is shorter.

     - Parameter l: The minimum length for the string.
     */
    func minLength(l: Int) -> ConversionStep<String, String> {
        func convert(s: String, ctx: ConversionContext) -> ConversionResult<String, ExtractError> {
            if s.characters.count >= l {
                return .Success(s)
            }
            return .Failure(ExtractError.StringTooShort(name: ctx.originalValue.name, value: s, minLength: l))
        }
        func help(ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                NSLocalizedString("Flue.Checks.String.MinLength.Help", bundle: flueBundle(), comment: "Flue: Check string minimum length: Help text. Parameters: minimum length"), ctx.valueParser.integerFormatter.stringFromNumber(l)!)
            return self.help(ctx) + [msg]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    /**
     Creates a `ConversionStep` that checks that the input string is at most `l` characters long.
     The `ConversionStep` will return a `ExtractError.StringTooLong` if the string is longer.

     - Parameter l: The maximum length for the string.
     */
    func maxLength(l: Int) -> ConversionStep<String, String> {
        func convert(s: String, ctx: ConversionContext) -> ConversionResult<String, ExtractError> {
            if s.characters.count <= l {
                return .Success(s)
            }
            return .Failure(ExtractError.StringTooLong(name: ctx.originalValue.name, value: s, maxLength: l))
        }
        func help(ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                NSLocalizedString("Flue.Checks.String.MaxLength.Help", bundle: flueBundle(), comment: "Flue: Check string maximum length: Help text. Parameters: maximum length"), ctx.valueParser.integerFormatter.stringFromNumber(l)!)
            return self.help(ctx) + [msg]
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
            return .Failure(ExtractError.ValueTooSmall(
                name: ctx.originalValue.name,
                value: ctx.originalValue.value!,
                shouldBeGreaterThan: ctx.valueParser.floatFormatter.stringFromNumber(limit)!))
        }
        func help(ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                NSLocalizedString("Flue.Checks.Double.GreaterThan.Help", bundle: flueBundle(), comment: "Flue: Check double is greater than value: Help text. Parameters: limit"), ctx.valueParser.floatFormatter.stringFromNumber(limit)!)
            return self.help(ctx) + [msg]
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
            return .Failure(ExtractError.ValueTooLarge(
                name: ctx.originalValue.name,
                value: ctx.originalValue.value!,
                shouldBeLessThan: ctx.valueParser.floatFormatter.stringFromNumber(limit)!))
        }
        func help(ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                NSLocalizedString("Flue.Checks.Double.LessThan.Help", bundle: flueBundle(), comment: "Flue: Check double is less than value: Help text. Parameters: limit"), ctx.valueParser.floatFormatter.stringFromNumber(limit)!)
            return self.help(ctx) + [msg]
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
            return .Failure(ExtractError.DateTooLate(
                name: ctx.originalValue.name,
                value: ctx.originalValue.value!,
                limit: ctx.valueParser.dateFormatter.stringFromDate(limit)))
        }
        func help(ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                NSLocalizedString("Flue.Checks.NSDate.Before.Help", bundle: flueBundle(), comment: "Flue: Check NSDate is before another date: Help text. Parameters: limit"), ctx.valueParser.dateFormatter.stringFromDate(limit))
            return self.help(ctx) + [msg]
        }

        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    func after(limit: NSDate) -> ConversionStep<NSDate, NSDate> {
        func convert(d: NSDate, ctx: ConversionContext) -> ConversionResult<NSDate, ExtractError> {
            if d.laterDate(limit) == d {
                return .Success(d)
            }
            return .Failure(ExtractError.DateTooEarly(
                name: ctx.originalValue.name,
                value: ctx.originalValue.value!,
                limit: ctx.valueParser.dateFormatter.stringFromDate(limit)))
        }
        func help(ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                NSLocalizedString("Flue.Checks.NSDate.After.Help", bundle: flueBundle(), comment: "Flue: Check NSDate is after another date: Help text. Parameters: limit"), ctx.valueParser.dateFormatter.stringFromDate(limit))
            return self.help(ctx) + [msg]
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
            let msg = String(format:
                NSLocalizedString("Flue.Extract.Name", bundle: flueBundle(), comment: "Flue: Extract named value: Help text. Parameters: name"),
                name)

            return [msg, extra]
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
            return self.help(NSLocalizedString("Flue.Extract.Type.String", bundle: flueBundle(), comment: "Flue: Extract value as String: Help text"))
        }
        return ConversionStep(input: self.inputForReader, convert: convert, help: help, context: self.conversionContext)
    }

    /// Creates a `ConversionStep` that parses the input string as an integer, using the locale initially passed in to the `ValueParser` constructor.
    /// The `ConversionStep` will return a `ExtractError.BadFormat` if parsing fails.
    public func asInt() -> ConversionStep<String, Int> {
        let typeName = NSLocalizedString("Flue.Extract.Type.Integer", bundle: flueBundle(), comment: "Flue: Extract value as Integer: Type description")

        func convert(s: String, ctx: ConversionContext) -> ConversionResult<Int, ExtractError> {
            guard let parsed = ctx.valueParser.integerFormatter.numberFromString(s) else {
                return .Failure(ExtractError.BadFormat(name: ctx.originalValue.name, value: s, expectType: typeName))
            }
            return .Success(parsed as Int)
        }
        func help(ctx: ConversionContext) -> [String] {
            return self.help(typeName)
        }

        return ConversionStep(input: self.inputForReader, convert: convert, help: help, context: self.conversionContext)
    }

    /// Creates a `ConversionStep` that parses the input string as a double, using the locale initially passed in to the `ValueParser` constructor.
    /// The `ConversionStep` will return a `ExtractError.BadFormat` if parsing fails.
    public func asDouble() -> ConversionStep<String, Double> {
        let typeName = NSLocalizedString("Flue.Extract.Type.Double", bundle: flueBundle(), comment: "Flue: Extract value as Double: Type description")

        func convert(s: String, ctx: ConversionContext) -> ConversionResult<Double, ExtractError> {
            guard let parsed = ctx.valueParser.floatFormatter.numberFromString(s) else {
                return .Failure(ExtractError.BadFormat(name: ctx.originalValue.name, value: s, expectType: typeName))
            }
            return .Success(parsed as Double)
        }
        func help(ctx: ConversionContext) -> [String] {
            return self.help(typeName)
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
            return self.help(NSLocalizedString("Flue.Extract.Type.Bool", bundle: flueBundle(), comment: "Flue: Extract value as Boolean: Help text"))
        }

        return ConversionStep(input: self.inputForReader, convert: convert, help: help, context: self.conversionContext)
    }

    public func asDate(df: NSDateFormatter) -> ConversionStep<String, NSDate> {
        func convert(s: String, ctx: ConversionContext) -> ConversionResult<NSDate, ExtractError> {
            if let parsed = df.dateFromString(s) {
                return .Success(parsed)
            }
            return .Failure(ExtractError.DateBadFormat(name: ctx.originalValue.name, value: s, format: df.dateFormat))
        }

        func help(ctx: ConversionContext) -> [String] {
            let msg = String(format: NSLocalizedString("Flue.Extract.Type.NSDate", bundle: flueBundle(), comment: "Flue: Extract value as NSDate: Help text. Parameters: Date format"), df.dateFormat)
            return self.help(msg)
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

internal func flueBundle() -> NSBundle {
    return NSBundle(forClass: ValueParser.self)
}
