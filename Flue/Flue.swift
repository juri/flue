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
    private let stringLoader: StringLoader

    /// Construct ValueParser for the given locale. Defaults to en_US_POSIX.
    public init(locale: NSLocale = NSLocale(localeIdentifier: "en_US_POSIX"), stringLoader: StringLoader = stringBundleLoader()) {
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

        self.stringLoader = stringLoader
    }

    /// Returns an ConversionStep object with a String result
    public func extract(value: String?, name: String? = nil) -> ConversionStep<String, String> {
        let errorBuilder = ErrorBuilder(integerFormatter: self.integerFormatter, floatFormatter: self.floatFormatter, dateFormatter: self.dateFormatter, stringLoader: self.stringLoader)

        func readValue() -> ConversionResult<String, ExtractError> {
            guard let val = value else {
                return .Failure(errorBuilder.valueMissing(name))
            }
            return .Success(val)
        }

        func convert(s: String, ctx: ConversionContext) -> ConversionResult<String, ExtractError> {
            return .Success(s)
        }

        func help(ctx: ConversionContext) -> [String] {
            if let n = name {
                return [n]
            }
            return []
        }

        let originalValue = OriginalValue(name: name, value: value)
        let conversionContext = ConversionContext(valueParser: self, errorBuilder: errorBuilder, stringLoader: self.stringLoader, originalValue: originalValue)

        return ConversionStep(input: readValue, convert: convert, help: help, context: conversionContext)
    }
}

public typealias StringLoader = ((String, String) -> String)

public func stringBundleLoader(bundle: NSBundle = flueBundle()) -> StringLoader {
    return { NSLocalizedString($0, bundle: bundle, comment: $1) }
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

    public func extract(key: String) -> ConversionStep<String,String> {
        return self.vp.extract(self.dict[key], name: key)
    }
}

internal struct ErrorBuilder {
    private let integerFormatter: NSNumberFormatter
    private let floatFormatter: NSNumberFormatter
    private let dateFormatter: NSDateFormatter
    private let stringLoader: StringLoader

    internal func valueMissing(name: String?) -> ExtractError {
        let desc: String
        if let n = name {
            desc = String(
                format: self.stringLoader("Flue.Error.ValueMissing.Named", "Flue: ValueMissing error, named. Parameters: name"),
                n)
        } else {
            desc = self.stringLoader("Flue.Error.ValueMissing.Anonymous", "Flue: ValueMissing error, no name")
        }
        return ExtractError.ValueMissing(name: name, localizedDescription: desc)
    }

    internal func badFormat(name: String?, value: String, expectType: String) -> ExtractError {
        let desc: String
        if let n = name {
            desc = String(
                format: self.stringLoader("Flue.Error.BadFormat.Named", "Flue: Format error, named. Parameters: name, value, expected type"),
                n, value, expectType)
        } else {
            desc = String(
                format: self.stringLoader("Flue.Error.BadFormat.Anonymous", "Flue: Format error, no name. Parameters: value, expected type"),
                value, expectType)
        }
        return ExtractError.BadFormat(name: name, value: value, expectType: expectType, localizedDescription: desc)
    }

    internal func intNotInRange(name: String?, value: Int, range: Range<Int>) -> ExtractError {
        let desc: String

        if let n = name {
            desc = String(
                format: self.stringLoader("Flue.Error.IntNotInRange.Named", "Flue: IntRange error, named. Parameters: name, value, range"),
                n, self.integerFormatter.stringFromNumber(value)!, range.description)
        } else {
            desc = String(
                format: self.stringLoader("Flue.Error.IntNotInRange.Anonymous", "Flue: IntRange error, no name. Parameters: value, range"),
                self.integerFormatter.stringFromNumber(value)!, range.description)
        }
        return ExtractError.IntNotInRange(name: name, value: value, range: range, localizedDescription: desc)
    }

    internal func valueTooSmall(name: String?, value: String, shouldBeGreaterThan: String) -> ExtractError {
        let desc: String

        if let n = name {
            desc = String(
                format: self.stringLoader("Flue.Error.ValueTooSmall.Named", "Flue: ValueTooSmall error, named. Parameters: name, value, limit"),
                n, value, shouldBeGreaterThan)
        } else {
            desc = String(
                format: self.stringLoader("Flue.Error.ValueTooSmall.Anonymous", "Flue: ValueTooSmall error, no name. Parameters: value, limit"),
                value, shouldBeGreaterThan)
        }

        return ExtractError.ValueTooSmall(name: name, value: value, shouldBeGreaterThan: shouldBeGreaterThan, localizedDescription: desc)
    }

    internal func valueTooLarge(name: String?, value: String, shouldBeLessThan: String) -> ExtractError {
        let desc: String

        if let n = name {
            desc = String(
                format: self.stringLoader("Flue.Error.ValueTooLarge.Named", "Flue: ValueTooLarge error, named. Parameters: name, value, limit"),
                n, value, shouldBeLessThan)
        } else {
            desc = String(
                format: self.stringLoader("Flue.Error.ValueTooLarge.Anonoymous", "Flue: ValueTooLarge error, no name. Parameters: value, limit"),
                value, shouldBeLessThan)
        }

        return ExtractError.ValueTooLarge(name: name, value: value, shouldBeLessThan: shouldBeLessThan, localizedDescription: desc)
    }

    internal func stringTooShort(name: String?, value: String, minLength: Int) -> ExtractError {
        let desc: String

        if let n = name {
            desc = String(
                format: self.stringLoader("Flue.Error.StringTooShort.Named", "Flue: StringMinLength error, named. Parameters: name, value, min length"),
                n, value, self.integerFormatter.stringFromNumber(minLength)!)
        } else {
            desc = String(
                format: self.stringLoader("Flue.Error.StringTooShort.Anonymous", "Flue: StringMinLength error, no name. Parameters: value, min length"),
                value, self.integerFormatter.stringFromNumber(minLength)!)
        }

        return ExtractError.StringTooShort(name: name, value: value, minLength: minLength, localizedDescription: desc)
    }

    internal func stringTooLong(name: String?, value: String, maxLength: Int) -> ExtractError {
        let desc: String
        if let n = name {
            desc = String(
                format: self.stringLoader("Flue.Error.StringTooLong.Named", "Flue: StringMaxLength error, named. Parameters: name, value, max length"),
                n, value, self.integerFormatter.stringFromNumber(maxLength)!)
        } else {
            desc = String(
                format: self.stringLoader("Flue.Error.StringTooLong.Anonymous", "Flue: StringMaxLength error, no name. Parameters: value, max length"),
                value, self.integerFormatter.stringFromNumber(maxLength)!)
        }

        return ExtractError.StringTooLong(name: name, value: value, maxLength: maxLength, localizedDescription: desc)
    }

    internal func noRegexpMatch(name: String?, value: String, regexp: String) -> ExtractError {
        let desc: String
        if let n = name {
            desc = String(
                format: self.stringLoader("Flue.Error.NoRegexpMatch.Named", "Flue: Regexp error, named: Parameters: name, value, regexp"),
                n, value, regexp)
        } else {
            desc = String(
                format: self.stringLoader("Flue.Error.NoRegexpMatch.Anonymous", "Flue: Regexp error, no name: Parameters: value, regexp"),
                value, regexp)
        }

        return ExtractError.NoRegexpMatch(name: name, value: value, regexp: regexp, localizedDescription: desc)
    }

    internal func dateBadFormat(name: String?, value: String, format: String) -> ExtractError {
        let desc: String
        if let n = name {
            desc = String(
                format: self.stringLoader("Flue.Error.DateBadFormat.Named", "Flue: DateFormat error, named. Parameters: name, value, format"),
                n, value, format)

        } else {
            desc = String(
                format: self.stringLoader("Flue.Error.DateBadFormat.Anonymous", "Flue: DateFormat error, no name. Parameters: value, format"),
                value, format)
        }

        return ExtractError.DateBadFormat(name: name, value: value, format: format, localizedDescription: desc)
    }

    internal func dateTooEarly(name: String?, value: NSDate, limit: NSDate) -> ExtractError {
        let desc: String
        if let n = name {
            desc = String(
                format: self.stringLoader("Flue.Error.DateTooEarly.Named", "Flue: DateTooEarly error, named. Parameters: name, value, limit"),
                n, self.dateFormatter.stringFromDate(value), self.dateFormatter.stringFromDate(limit))
        } else {
            desc = String(
                format: self.stringLoader("Flue.Error.DateTooEarly.Anonymous", "Flue: DateTooEarly error, no name. Parameters: value, limit"),
                self.dateFormatter.stringFromDate(value), self.dateFormatter.stringFromDate(limit))
        }

        return ExtractError.DateTooEarly(name: name, value: value, limit: limit, localizedDescription: desc)
    }

    internal func dateTooLate(name: String?, value: NSDate, limit: NSDate) -> ExtractError {
        let desc: String
        if let n = name {
            desc = String(
                format: self.stringLoader("Flue.Error.DateTooLate.Named", "Flue: DateTooLate error, named. Parameters: name, value, limit"),
                n, self.dateFormatter.stringFromDate(value), self.dateFormatter.stringFromDate(limit))
        } else {
            desc = String(
                format: self.stringLoader("Flue.Error.DateTooLate.Anonymous", "Flue: DateTooLate error, no name. Parameters: name, value, limit"),
                self.dateFormatter.stringFromDate(value), self.dateFormatter.stringFromDate(limit))
        }

        return ExtractError.DateTooLate(name: name, value: value, limit: limit, localizedDescription: desc)
    }

    internal func fromError(e: ErrorType) -> ExtractError {
        let errorDesc: String
        if let ep = e as? CustomStringConvertible {
            errorDesc = ep.description
        } else {
            errorDesc = self.stringLoader("Flue.Error.UnknownError", "Flue: Wrapping an unexpected error that's not CustomStringConvertible")
        }
        return .OtherError(errorDesc)
    }
}


/**
 ExtractError is an enum for the errors emitted by the built-in Flue functions.
 */
public enum ExtractError: ErrorType, CustomStringConvertible, Equatable {
    /// Flue returns ValueMissing when the parser received a nil value.
    case ValueMissing(name: String?, localizedDescription: String)
    /// Flue returns BadFormat when conversion to a different type fails.
    case BadFormat(name: String?, value: String, expectType: String, localizedDescription: String)
    /// Flue returns IntNotInRange when `range` fails on an integer value.
    case IntNotInRange(name: String?, value: Int, range: Range<Int>, localizedDescription: String)
    /// Flue returns ValueTooSmall when a numeric value is smaller than allowed.
    case ValueTooSmall(name: String?, value: String, shouldBeGreaterThan: String, localizedDescription: String)
    /// Flue returns ValueTooSmall when a numeric value is larger than allowed.
    case ValueTooLarge(name: String?, value: String, shouldBeLessThan: String, localizedDescription: String)
    /// Flue returns StringTooShort when `minLength` fails on a string value.
    case StringTooShort(name: String?, value: String, minLength: Int, localizedDescription: String)
    /// Flue returns StringTooLong when `maxLength` fails on a string value.
    case StringTooLong(name: String?, value: String, maxLength: Int, localizedDescription: String)
    /// Flue returns NoRegexpMatch when `regexp` fails on a string value.
    case NoRegexpMatch(name: String?, value: String, regexp: String, localizedDescription: String)
    /// Flue returns DateBadFormat when `value` couldn't be parsed as a NSDate with `format`.
    case DateBadFormat(name: String?, value: String, format: String, localizedDescription: String)
    /// Flue returns DateTooEarly when `value` represented a date that was earlier than `limit`.
    case DateTooEarly(name: String?, value: NSDate, limit: NSDate, localizedDescription: String)
    /// Flue returns DateTooLate when `value` represented a date that was later than `limit`.
    case DateTooLate(name: String?, value: NSDate, limit: NSDate, localizedDescription: String)
    /// Flue returns OtherError when an unexpected error occurs.
    case OtherError(String)

    public var description: String {
        switch self {
        case let .ValueMissing(_, localizedDescription):
            return localizedDescription

        case let .BadFormat(_, _, _, localizedDescription):
            return localizedDescription

        case let .IntNotInRange(_, _, _, localizedDescription):
            return localizedDescription

        case let .ValueTooSmall(_, _, _, localizedDescription):
            return localizedDescription

        case let .ValueTooLarge(_, _, _, localizedDescription):
            return localizedDescription

        case let .StringTooShort(_, _, _, localizedDescription):
            return localizedDescription

        case let .StringTooLong(_, _, _, localizedDescription):
            return localizedDescription

        case let .NoRegexpMatch(_, _, _, localizedDescription):
            return localizedDescription

        case let .DateBadFormat(_, _, _, localizedDescription):
            return localizedDescription

        case let .DateTooEarly(_, _, _, localizedDescription):
            return localizedDescription

        case let .DateTooLate(_, _, _, localizedDescription):
            return localizedDescription
            
        case .OtherError(let msg):
            return msg
        }
    }
}

public func ==(ee1: ExtractError, ee2: ExtractError) -> Bool {
    switch (ee1, ee2) {
    case let (.ValueMissing(n1, _), .ValueMissing(n2, _)):
        return n1 == n2
    case let (.BadFormat(name1, value1, expectType1, _), .BadFormat(name2, value2, expectType2, _)):
        return name1 == name2 && value1 == value2 && expectType1 == expectType2
    case let (.IntNotInRange(name1, value1, range1, _), .IntNotInRange(name2, value2, range2, _)):
        return name1 == name2 && value1 == value2 && range1 == range2
    case let (.ValueTooSmall(n1, v1, l1, _), .ValueTooSmall(n2, v2, l2, _)):
        return n1 == n2 && v1 == v2 && l1 == l2
    case let (.ValueTooLarge(n1, v1, l1, _), .ValueTooLarge(n2, v2, l2, _)):
        return n1 == n2 && v1 == v2 && l1 == l2
    case let (.StringTooShort(name1, value1, l1, _), .StringTooShort(name2, value2, l2, _)):
        return name1 == name2 && value1 == value2 && l1 == l2
    case let (.StringTooLong(name1, value1, l1, _), .StringTooLong(name2, value2, l2, _)):
        return name1 == name2 && value1 == value2 && l1 == l2
    case let (.NoRegexpMatch(n1, v1, r1, _), .NoRegexpMatch(n2, v2, r2, _)):
        return n1 == n2 && v1 == v2 && r1 == r2
    case let (.DateBadFormat(n1, v1, f1, _), .DateBadFormat(n2, v2, f2, _)):
        return n1 == n2 && v1 == v2 && f1 == f2
    case let (.DateTooEarly(n1, v1, l1, _), .DateTooEarly(n2, v2, l2, _)):
        return n1 == n2 && v1 == v2 && l1 == l2
    case let (.DateTooLate(n1, v1, l1, _), .DateTooLate(n2, v2, l2, _)):
        return n1 == n2 && v1 == v2 && l1 == l2
    case let (.OtherError(v1), .OtherError(v2)):
        return v1 == v2
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
    internal let errorBuilder: ErrorBuilder
    let stringLoader: StringLoader
    let originalValue: OriginalValue
}

/**
 ConversionStep is one step in a chain of conversions or validations.
 
 It's parametrized with three functions that provide the value handling logic:

 - `input` reads the value from previous step.
 - `convert` converts the value from `input` to the next type.
 - `help` returns the current array of help messages.
 */
public struct ConversionStep<Input, Output>: ConversionStepProtocol, UsageProvider {
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

    /// Adds a string to the help array. The addition can be placed at either end
    /// of the array.
    public func addHelp(s: String, prefix: Bool = false) -> ConversionStep<Input, Output> {
        let oldHelp = self.help
        let newHelp = { (cctx: ConversionContext) -> [String] in
            if prefix {
                return [s] + oldHelp(cctx)
            }
            return oldHelp(cctx) + [s]
        }
        return ConversionStep(input: self.input, convert: self.convert, help: newHelp, context: self.context)
    }

    /// Returns the current help array.
    public func usage() -> [String] {
        return self.help(self.context)
    }
}

/// UsageProviders provide an `usage` method. It makes it easier to deal with a collection
/// of `ConversionStep`s when collecting their help messages.
public protocol UsageProvider {
    /// Returns the current help array.
    func usage() -> [String]
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

    func addHelp(s: String, prefix: Bool) -> Self
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
            return .Failure(ctx.errorBuilder.badFormat(ctx.originalValue.name, value: ctx.originalValue.value ?? "", expectType: "\(NewType.self)"))
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
    public func range(r: Range<Int>) -> ConversionStep<Int, Int> {
        func convert(i: Int, ctx: ConversionContext) -> ConversionResult<Int, ExtractError> {
            if r.contains(i) {
                return .Success(i)
            }
            return .Failure(ctx.errorBuilder.intNotInRange(ctx.originalValue.name, value: i, range: r))
        }
        func help(ctx: ConversionContext) -> [String] {
            let msg = String(format: ctx.stringLoader("Flue.Checks.Int.Range.Help", "Flue: Check int range: Help text. Parameters: Range"), r.description)
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
    public func minLength(l: Int) -> ConversionStep<String, String> {
        func convert(s: String, ctx: ConversionContext) -> ConversionResult<String, ExtractError> {
            if s.characters.count >= l {
                return .Success(s)
            }
            return .Failure(ctx.errorBuilder.stringTooShort(ctx.originalValue.name, value: s, minLength: l))
        }
        func help(ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                ctx.stringLoader("Flue.Checks.String.MinLength.Help", "Flue: Check string minimum length: Help text. Parameters: minimum length"), ctx.valueParser.integerFormatter.stringFromNumber(l)!)
            return self.help(ctx) + [msg]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    /**
     Creates a `ConversionStep` that checks that the input string is at most `l` characters long.
     The `ConversionStep` will return a `ExtractError.StringTooLong` if the string is longer.

     - Parameter l: The maximum length for the string.
     */
    public func maxLength(l: Int) -> ConversionStep<String, String> {
        func convert(s: String, ctx: ConversionContext) -> ConversionResult<String, ExtractError> {
            if s.characters.count <= l {
                return .Success(s)
            }
            return .Failure(ctx.errorBuilder.stringTooLong(ctx.originalValue.name, value: s, maxLength: l))
        }
        func help(ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                ctx.stringLoader("Flue.Checks.String.MaxLength.Help", "Flue: Check string maximum length: Help text. Parameters: maximum length"), ctx.valueParser.integerFormatter.stringFromNumber(l)!)
            return self.help(ctx) + [msg]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    /// Creates a `ConversionStep` that parses the input string as an integer, using the locale initially passed in to the `ValueParser` constructor.
    /// The `ConversionStep` will return a `ExtractError.BadFormat` if parsing fails.
    public func asInt() -> ConversionStep<String, Int> {
        func typeName(stringLoader: StringLoader) -> String {
             return stringLoader("Flue.Extract.Type.Integer", "Flue: Extract value as Integer: Type description")
        }

        func convert(s: String, ctx: ConversionContext) -> ConversionResult<Int, ExtractError> {
            guard let parsed = ctx.valueParser.integerFormatter.numberFromString(s) else {
                return .Failure(ctx.errorBuilder.badFormat(ctx.originalValue.name, value: s, expectType: typeName(ctx.stringLoader)))
            }
            return .Success(parsed as Int)
        }
        func help(ctx: ConversionContext) -> [String] {
            return self.help(ctx) + [typeName(ctx.stringLoader)]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    /// Creates a `ConversionStep` that parses the input string as a double, using the locale initially passed in to the `ValueParser` constructor.
    /// The `ConversionStep` will return a `ExtractError.BadFormat` if parsing fails.
    public func asDouble() -> ConversionStep<String, Double> {
        func typeName(stringLoader: StringLoader) -> String {
            return stringLoader("Flue.Extract.Type.Double", "Flue: Extract value as Double: Type description")
        }

        func convert(s: String, ctx: ConversionContext) -> ConversionResult<Double, ExtractError> {
            guard let parsed = ctx.valueParser.floatFormatter.numberFromString(s) else {
                return .Failure(ctx.errorBuilder.badFormat(ctx.originalValue.name, value: s, expectType: typeName(ctx.stringLoader)))
            }
            return .Success(parsed as Double)
        }
        func help(ctx: ConversionContext) -> [String] {
            return self.help(ctx) + [typeName(ctx.stringLoader)]
        }

        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    /// Creates a `ConversionStep` that parses the input string as a boolean, using `NSString`'s `boolValue` method.
    public func asBool() -> ConversionStep<String, Bool> {
        func convert(s: String, ctx: ConversionContext) -> ConversionResult<Bool, ExtractError> {
            let bval = (s as NSString).boolValue
            return .Success(bval)
        }

        func help(ctx: ConversionContext) -> [String] {
            return self.help(ctx) + [ctx.stringLoader("Flue.Extract.Type.Bool", "Flue: Extract value as Boolean: Help text")]
        }

        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    public func asDate(df: NSDateFormatter) -> ConversionStep<String, NSDate> {
        func convert(s: String, ctx: ConversionContext) -> ConversionResult<NSDate, ExtractError> {
            if let parsed = df.dateFromString(s) {
                return .Success(parsed)
            }
            return .Failure(ctx.errorBuilder.dateBadFormat(ctx.originalValue.name, value: s, format: df.dateFormat))
        }

        func help(ctx: ConversionContext) -> [String] {
            let msg = String(format: ctx.stringLoader("Flue.Extract.Type.NSDate", "Flue: Extract value as NSDate: Help text. Parameters: Date format"), df.dateFormat)
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
    public func greaterThan(limit: Double) -> ConversionStep<Double, Double> {
        func convert(d: Double, ctx: ConversionContext) -> ConversionResult<Double, ExtractError> {
            if d > limit {
                return .Success(d)
            }
            return .Failure(ctx.errorBuilder.valueTooSmall(
                ctx.originalValue.name,
                value: ctx.originalValue.value!,
                shouldBeGreaterThan: ctx.valueParser.floatFormatter.stringFromNumber(limit)!))

        }
        func help(ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                ctx.stringLoader("Flue.Checks.Double.GreaterThan.Help", "Flue: Check double is greater than value: Help text. Parameters: limit"), ctx.valueParser.floatFormatter.stringFromNumber(limit)!)
            return self.help(ctx) + [msg]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    /**
     Creates a `ConversionStep` that checks that the input double is less than `limit`.

     - Parameter limit: The upper non-inclusive bound for the value.
     */
    public func lessThan(limit: Double) -> ConversionStep<Double, Double> {
        func convert(d: Double, ctx: ConversionContext) -> ConversionResult<Double, ExtractError> {
            if d < limit {
                return .Success(d)
            }
            return .Failure(ctx.errorBuilder.valueTooLarge(
                ctx.originalValue.name,
                value: ctx.originalValue.value!,
                shouldBeLessThan: ctx.valueParser.floatFormatter.stringFromNumber(limit)!))

        }
        func help(ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                ctx.stringLoader("Flue.Checks.Double.LessThan.Help", "Flue: Check double is less than value: Help text. Parameters: limit"), ctx.valueParser.floatFormatter.stringFromNumber(limit)!)
            return self.help(ctx) + [msg]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }
}

extension ConversionStepProtocol where Output == NSDate {
    public func before(limit: NSDate) -> ConversionStep<NSDate, NSDate> {
        func convert(d: NSDate, ctx: ConversionContext) -> ConversionResult<NSDate, ExtractError> {
            if d.earlierDate(limit) == d {
                return .Success(d)
            }
            return .Failure(ctx.errorBuilder.dateTooLate(
                ctx.originalValue.name,
                value: d,
                limit: limit))

        }
        func help(ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                ctx.stringLoader("Flue.Checks.NSDate.Before.Help", "Flue: Check NSDate is before another date: Help text. Parameters: limit"), ctx.valueParser.dateFormatter.stringFromDate(limit))
            return self.help(ctx) + [msg]
        }

        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    public func after(limit: NSDate) -> ConversionStep<NSDate, NSDate> {
        func convert(d: NSDate, ctx: ConversionContext) -> ConversionResult<NSDate, ExtractError> {
            if d.laterDate(limit) == d {
                return .Success(d)
            }
            return .Failure(ctx.errorBuilder.dateTooEarly(
                ctx.originalValue.name,
                value: d,
                limit: limit))

        }
        func help(ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                ctx.stringLoader("Flue.Checks.NSDate.After.Help", "Flue: Check NSDate is after another date: Help text. Parameters: limit"), ctx.valueParser.dateFormatter.stringFromDate(limit))
            return self.help(ctx) + [msg]
        }

        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }
}

internal func flueBundle() -> NSBundle {
    return NSBundle(forClass: ValueParser.self)
}
