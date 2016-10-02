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
open class ValueParser {
    fileprivate let integerFormatter: NumberFormatter
    fileprivate let floatFormatter: NumberFormatter
    fileprivate let dateFormatter: DateFormatter
    fileprivate let stringLoader: StringLoader

    /// Construct ValueParser for the given locale. Defaults to en_US_POSIX.
    public init(locale: Locale = Locale(identifier: "en_US_POSIX"), stringLoader: @escaping StringLoader = stringBundleLoader()) {
        let integerFormatter = NumberFormatter()
        integerFormatter.locale = locale
        integerFormatter.maximumFractionDigits = 0
        integerFormatter.allowsFloats = false
        self.integerFormatter = integerFormatter

        let floatFormatter = NumberFormatter()
        floatFormatter.locale = locale
        floatFormatter.maximumFractionDigits = 100
        self.floatFormatter = floatFormatter

        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .short
        self.dateFormatter = dateFormatter

        self.stringLoader = stringLoader
    }

    /// Returns an ConversionStep object with a String result
    open func extract(_ value: String?, name: String? = nil) -> ConversionStep<String, String> {
        let errorBuilder = ErrorBuilder(integerFormatter: self.integerFormatter, floatFormatter: self.floatFormatter, dateFormatter: self.dateFormatter, stringLoader: self.stringLoader)

        func readValue() -> ConversionResult<String> {
            guard let val = value else {
                return .failure(errorBuilder.valueMissing(name))
            }
            return .success(val)
        }

        func convert(_ s: String, ctx: ConversionContext) -> ConversionResult<String> {
            return .success(s)
        }

        func help(_ ctx: ConversionContext) -> [String] {
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

public func stringBundleLoader(_ bundle: Bundle = flueBundle()) -> StringLoader {
    return { NSLocalizedString($0, bundle: bundle, comment: $1) }
}

/**
 DictParser extracts values from a [String: String] dictionary.
 */
open class DictParser {
    fileprivate let dict: [String: String]
    open let vp: ValueParser

    public init(dict: [String: String], valueParser: ValueParser = ValueParser()) {
        self.dict = dict
        self.vp = valueParser
    }

    open func extract(_ key: String) -> ConversionStep<String,String> {
        return self.vp.extract(self.dict[key], name: key)
    }
}

/**
 ConversionInfoProvider gives interface to the usage strings and error info
 of a conversion.
 */
public protocol ConversionInfoProvider {
    func usage() -> [String]
    func error() -> Error?
}

/**
 Conversions collects usage info and errors from multiple ValueParser calls.
 */
public class Conversions {
    private var conversions: [ConversionInfoProvider] = []

    public init() {}

    public func add<A, B>(_ conversion: ConversionStep<A, B>) -> ConversionStep<A, B> {
        self.conversions.append(conversion)
        return conversion
    }

    public func usage() -> [[String]] {
        return conversions.map { $0.usage() }
    }

    public func errors() -> [Error] {
        return conversions.flatMap { $0.error() }
    }
}

internal struct ErrorBuilder {
    fileprivate let integerFormatter: NumberFormatter
    fileprivate let floatFormatter: NumberFormatter
    fileprivate let dateFormatter: DateFormatter
    fileprivate let stringLoader: StringLoader

    internal func valueMissing(_ name: String?) -> ExtractError {
        let desc: String
        if let n = name {
            desc = String(
                format: self.stringLoader("Flue.Error.ValueMissing.Named", "Flue: ValueMissing error, named. Parameters: name"),
                n)
        } else {
            desc = self.stringLoader("Flue.Error.ValueMissing.Anonymous", "Flue: ValueMissing error, no name")
        }
        return ExtractError.valueMissing(name: name, localizedDescription: desc)
    }

    internal func badFormat(_ name: String?, value: String, expectType: String) -> ExtractError {
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
        return ExtractError.badFormat(name: name, value: value, expectType: expectType, localizedDescription: desc)
    }

    internal func intNotInRange(_ name: String?, value: Int, range: CountableClosedRange<Int>) -> ExtractError {
        let desc: String

        if let n = name {
            desc = String(
                format: self.stringLoader("Flue.Error.IntNotInRange.Named", "Flue: IntRange error, named. Parameters: name, value, range"),
                n, self.integerFormatter.string(from: NSNumber(value: value))!, range.description)
        } else {
            desc = String(
                format: self.stringLoader("Flue.Error.IntNotInRange.Anonymous", "Flue: IntRange error, no name. Parameters: value, range"),
                self.integerFormatter.string(from: NSNumber(value: value))!, range.description)
        }
        return ExtractError.intNotInRange(name: name, value: value, range: range, localizedDescription: desc)
    }

    internal func valueTooSmall(_ name: String?, value: String, shouldBeGreaterThan: String) -> ExtractError {
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

        return ExtractError.valueTooSmall(name: name, value: value, shouldBeGreaterThan: shouldBeGreaterThan, localizedDescription: desc)
    }

    internal func valueTooLarge(_ name: String?, value: String, shouldBeLessThan: String) -> ExtractError {
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

        return ExtractError.valueTooLarge(name: name, value: value, shouldBeLessThan: shouldBeLessThan, localizedDescription: desc)
    }

    internal func stringTooShort(_ name: String?, value: String, minLength: Int) -> ExtractError {
        let desc: String

        if let n = name {
            desc = String(
                format: self.stringLoader("Flue.Error.StringTooShort.Named", "Flue: StringMinLength error, named. Parameters: name, value, min length"),
                n, value, self.integerFormatter.string(from: NSNumber(value: minLength))!)
        } else {
            desc = String(
                format: self.stringLoader("Flue.Error.StringTooShort.Anonymous", "Flue: StringMinLength error, no name. Parameters: value, min length"),
                value, self.integerFormatter.string(from: NSNumber(value: minLength))!)
        }

        return ExtractError.stringTooShort(name: name, value: value, minLength: minLength, localizedDescription: desc)
    }

    internal func stringTooLong(_ name: String?, value: String, maxLength: Int) -> ExtractError {
        let desc: String
        if let n = name {
            desc = String(
                format: self.stringLoader("Flue.Error.StringTooLong.Named", "Flue: StringMaxLength error, named. Parameters: name, value, max length"),
                n, value, self.integerFormatter.string(from: NSNumber(value: maxLength))!)
        } else {
            desc = String(
                format: self.stringLoader("Flue.Error.StringTooLong.Anonymous", "Flue: StringMaxLength error, no name. Parameters: value, max length"),
                value, self.integerFormatter.string(from: NSNumber(value: maxLength))!)
        }

        return ExtractError.stringTooLong(name: name, value: value, maxLength: maxLength, localizedDescription: desc)
    }

    internal func noRegexpMatch(_ name: String?, value: String, regexp: String) -> ExtractError {
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

        return ExtractError.noRegexpMatch(name: name, value: value, regexp: regexp, localizedDescription: desc)
    }

    internal func dateBadFormat(_ name: String?, value: String, format: String) -> ExtractError {
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

        return ExtractError.dateBadFormat(name: name, value: value, format: format, localizedDescription: desc)
    }

    internal func dateTooEarly(_ name: String?, value: Date, limit: Date) -> ExtractError {
        let desc: String
        if let n = name {
            desc = String(
                format: self.stringLoader("Flue.Error.DateTooEarly.Named", "Flue: DateTooEarly error, named. Parameters: name, value, limit"),
                n, self.dateFormatter.string(from: value), self.dateFormatter.string(from: limit))
        } else {
            desc = String(
                format: self.stringLoader("Flue.Error.DateTooEarly.Anonymous", "Flue: DateTooEarly error, no name. Parameters: value, limit"),
                self.dateFormatter.string(from: value), self.dateFormatter.string(from: limit))
        }

        return ExtractError.dateTooEarly(name: name, value: value, limit: limit, localizedDescription: desc)
    }

    internal func dateTooLate(_ name: String?, value: Date, limit: Date) -> ExtractError {
        let desc: String
        if let n = name {
            desc = String(
                format: self.stringLoader("Flue.Error.DateTooLate.Named", "Flue: DateTooLate error, named. Parameters: name, value, limit"),
                n, self.dateFormatter.string(from: value), self.dateFormatter.string(from: limit))
        } else {
            desc = String(
                format: self.stringLoader("Flue.Error.DateTooLate.Anonymous", "Flue: DateTooLate error, no name. Parameters: name, value, limit"),
                self.dateFormatter.string(from: value), self.dateFormatter.string(from: limit))
        }

        return ExtractError.dateTooLate(name: name, value: value, limit: limit, localizedDescription: desc)
    }

    internal func fromError(_ e: Error) -> ExtractError {
        let errorDesc: String
        if let ep = e as? CustomStringConvertible {
            errorDesc = ep.description
        } else {
            errorDesc = self.stringLoader("Flue.Error.UnknownError", "Flue: Wrapping an unexpected error that's not CustomStringConvertible")
        }
        return .otherError(errorDesc)
    }
}


/**
 ExtractError is an enum for the errors emitted by the built-in Flue functions.
 */
public enum ExtractError: Error, CustomStringConvertible, Equatable {
    /// Flue returns ValueMissing when the parser received a nil value.
    case valueMissing(name: String?, localizedDescription: String)
    /// Flue returns BadFormat when conversion to a different type fails.
    case badFormat(name: String?, value: String, expectType: String, localizedDescription: String)
    /// Flue returns IntNotInRange when `range` fails on an integer value.
    case intNotInRange(name: String?, value: Int, range: CountableClosedRange<Int>, localizedDescription: String)
    /// Flue returns ValueTooSmall when a numeric value is smaller than allowed.
    case valueTooSmall(name: String?, value: String, shouldBeGreaterThan: String, localizedDescription: String)
    /// Flue returns ValueTooSmall when a numeric value is larger than allowed.
    case valueTooLarge(name: String?, value: String, shouldBeLessThan: String, localizedDescription: String)
    /// Flue returns StringTooShort when `minLength` fails on a string value.
    case stringTooShort(name: String?, value: String, minLength: Int, localizedDescription: String)
    /// Flue returns StringTooLong when `maxLength` fails on a string value.
    case stringTooLong(name: String?, value: String, maxLength: Int, localizedDescription: String)
    /// Flue returns NoRegexpMatch when `regexp` fails on a string value.
    case noRegexpMatch(name: String?, value: String, regexp: String, localizedDescription: String)
    /// Flue returns DateBadFormat when `value` couldn't be parsed as a NSDate with `format`.
    case dateBadFormat(name: String?, value: String, format: String, localizedDescription: String)
    /// Flue returns DateTooEarly when `value` represented a date that was earlier than `limit`.
    case dateTooEarly(name: String?, value: Date, limit: Date, localizedDescription: String)
    /// Flue returns DateTooLate when `value` represented a date that was later than `limit`.
    case dateTooLate(name: String?, value: Date, limit: Date, localizedDescription: String)
    /// Flue returns OtherError when an unexpected error occurs.
    case otherError(String)

    public var description: String {
        switch self {
        case let .valueMissing(_, localizedDescription):
            return localizedDescription

        case let .badFormat(_, _, _, localizedDescription):
            return localizedDescription

        case let .intNotInRange(_, _, _, localizedDescription):
            return localizedDescription

        case let .valueTooSmall(_, _, _, localizedDescription):
            return localizedDescription

        case let .valueTooLarge(_, _, _, localizedDescription):
            return localizedDescription

        case let .stringTooShort(_, _, _, localizedDescription):
            return localizedDescription

        case let .stringTooLong(_, _, _, localizedDescription):
            return localizedDescription

        case let .noRegexpMatch(_, _, _, localizedDescription):
            return localizedDescription

        case let .dateBadFormat(_, _, _, localizedDescription):
            return localizedDescription

        case let .dateTooEarly(_, _, _, localizedDescription):
            return localizedDescription

        case let .dateTooLate(_, _, _, localizedDescription):
            return localizedDescription
            
        case .otherError(let msg):
            return msg
        }
    }
}

public func ==(ee1: ExtractError, ee2: ExtractError) -> Bool {
    switch (ee1, ee2) {
    case let (.valueMissing(n1, _), .valueMissing(n2, _)):
        return n1 == n2
    case let (.badFormat(name1, value1, expectType1, _), .badFormat(name2, value2, expectType2, _)):
        return name1 == name2 && value1 == value2 && expectType1 == expectType2
    case let (.intNotInRange(name1, value1, range1, _), .intNotInRange(name2, value2, range2, _)):
        return name1 == name2 && value1 == value2 && range1 == range2
    case let (.valueTooSmall(n1, v1, l1, _), .valueTooSmall(n2, v2, l2, _)):
        return n1 == n2 && v1 == v2 && l1 == l2
    case let (.valueTooLarge(n1, v1, l1, _), .valueTooLarge(n2, v2, l2, _)):
        return n1 == n2 && v1 == v2 && l1 == l2
    case let (.stringTooShort(name1, value1, l1, _), .stringTooShort(name2, value2, l2, _)):
        return name1 == name2 && value1 == value2 && l1 == l2
    case let (.stringTooLong(name1, value1, l1, _), .stringTooLong(name2, value2, l2, _)):
        return name1 == name2 && value1 == value2 && l1 == l2
    case let (.noRegexpMatch(n1, v1, r1, _), .noRegexpMatch(n2, v2, r2, _)):
        return n1 == n2 && v1 == v2 && r1 == r2
    case let (.dateBadFormat(n1, v1, f1, _), .dateBadFormat(n2, v2, f2, _)):
        return n1 == n2 && v1 == v2 && f1 == f2
    case let (.dateTooEarly(n1, v1, l1, _), .dateTooEarly(n2, v2, l2, _)):
        return n1 == n2 && v1 == v2 && l1 == l2
    case let (.dateTooLate(n1, v1, l1, _), .dateTooLate(n2, v2, l2, _)):
        return n1 == n2 && v1 == v2 && l1 == l2
    case let (.otherError(v1), .otherError(v2)):
        return v1 == v2
    default:
        return false
    }
}

/**
 ConversionResult is a Success/Failure result enum for conversions.
 */
public enum ConversionResult<T> {
    case success(T)
    case failure(Error)

    var error: Error? {
        switch self {
        case .success(_): return nil
        case .failure(let e): return e
        }
    }
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
public struct ConversionStep<Input, Output>: ConversionStepProtocol, ConversionInfoProvider {
    public let input: () -> ConversionResult<Input>
    public let convert: (Input, ConversionContext) -> ConversionResult<Output>
    public let help: (ConversionContext) -> [String]
    public let context: ConversionContext

    /// Returns a `ConversionContext` containing either the value from `input` processed through `convert` or the error it contained.
    public func readValue() -> ConversionResult<Output> {
        let res = self.input()
        switch res {
        case .success(let v): return self.convert(v, self.context)
        case .failure(let e): return .failure(e)
        }
    }

    /// Returns the success value from `readValue` or throws the error.
    ///
    /// - Throws: The error contained in the `ConversionContext` returned by `readValue`.
    public func required() throws -> Output {
        switch self.readValue() {
        case .success(let v): return v
        case .failure(let e): throw e
        }
    }

    /// Returns the success value from `readValue` or the default value given as parameter.
    ///
    /// - Parameter v: default value to return if `readValue`'s return value contained an error.
    public func defaultValue(_ v: Output) -> Output {
        switch self.readValue() {
        case .success(let v): return v
        case .failure(_): return v
        }
    }

    /// Returns an optional containing the success value from `readValue` or nil.
    public func optional() -> Output? {
        switch self.readValue() {
        case .success(let v): return v
        case .failure(_): return nil
        }
    }

    /// Returns the error if there was a failure or nil
    public func error() -> Error? {
        return self.readValue().error
    }

    /// Adds a string to the help array. The addition can be placed either before or after 
    /// the previous entry.
    public func addHelp(_ s: String, prefix: Bool = false) -> ConversionStep<Input, Output> {
        let oldHelp = self.help
        let newHelp = { (cctx: ConversionContext) -> [String] in
            var helps = oldHelp(cctx)
            if prefix {
                if let last = helps.popLast() {
                    return helps + [s, last]
                }
            }
            return helps + [s]
        }
        return ConversionStep(input: self.input, convert: self.convert, help: newHelp, context: self.context)
    }

    /// Returns the current help array.
    public func usage() -> [String] {
        return self.help(self.context)
    }
}

/**
 Helper protocol for `ConversionStep` for adding type specific extension methods.
 */
public protocol ConversionStepProtocol {
    associatedtype Input
    associatedtype Output

    var input: () -> ConversionResult<Input> { get }
    var convert: (Input, ConversionContext) -> ConversionResult<Output> { get }
    var help: (ConversionContext) -> [String] { get }
    var context: ConversionContext { get }

    func addHelp(_ s: String, prefix: Bool) -> Self
    func readValue() -> ConversionResult<Output>
}

public extension ConversionStepProtocol {
    /**
     Creates a step that converts the input value to a new type, as specified by the function in the `convert` parameter.

     - Parameter convert: A function that can be used as the `convert` value in a `ConversionStep`.
     - Parameter help: A string to use as the help string for this step. If nil, it will default to a string describing the type returned by `convert`.
     */
    public func asType<NewType>(_ convert: @escaping ((Output, ConversionContext) -> ConversionResult<NewType>), help: String? = nil) -> ConversionStep<Output,NewType> {
        func helpFunc(_ ctx: ConversionContext) -> [String] {
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
    public func asType<NewType>(_ convert: @escaping ((Output, ConversionContext) -> NewType?), help: String? = nil) -> ConversionStep<Output,NewType> {
        func cwrap(_ v: Output, ctx: ConversionContext) -> ConversionResult<NewType> {
            if let cv = convert(v, ctx) {
                return .success(cv)
            }
            return .failure(ctx.errorBuilder.badFormat(ctx.originalValue.name, value: ctx.originalValue.value ?? "", expectType: String(describing: NewType.self)))
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
    public func range(_ r: CountableClosedRange<Int>) -> ConversionStep<Int, Int> {
        func convert(_ i: Int, ctx: ConversionContext) -> ConversionResult<Int> {
            if r.contains(i) {
                return .success(i)
            }
            return .failure(ctx.errorBuilder.intNotInRange(ctx.originalValue.name, value: i, range: r))
        }
        func help(_ ctx: ConversionContext) -> [String] {
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
    public func minLength(_ l: Int) -> ConversionStep<String, String> {
        func convert(_ s: String, ctx: ConversionContext) -> ConversionResult<String> {
            if s.characters.count >= l {
                return .success(s)
            }
            return .failure(ctx.errorBuilder.stringTooShort(ctx.originalValue.name, value: s, minLength: l))
        }
        func help(_ ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                ctx.stringLoader("Flue.Checks.String.MinLength.Help", "Flue: Check string minimum length: Help text. Parameters: minimum length"), ctx.valueParser.integerFormatter.string(from: NSNumber(value: l))!)
            return self.help(ctx) + [msg]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    /**
     Creates a `ConversionStep` that checks that the input string is at most `l` characters long.
     The `ConversionStep` will return a `ExtractError.StringTooLong` if the string is longer.

     - Parameter l: The maximum length for the string.
     */
    public func maxLength(_ l: Int) -> ConversionStep<String, String> {
        func convert(_ s: String, ctx: ConversionContext) -> ConversionResult<String> {
            if s.characters.count <= l {
                return .success(s)
            }
            return .failure(ctx.errorBuilder.stringTooLong(ctx.originalValue.name, value: s, maxLength: l))
        }
        func help(_ ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                ctx.stringLoader("Flue.Checks.String.MaxLength.Help", "Flue: Check string maximum length: Help text. Parameters: maximum length"), ctx.valueParser.integerFormatter.string(from: NSNumber(value: l))!)
            return self.help(ctx) + [msg]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    /// Creates a `ConversionStep` that parses the input string as an integer, using the locale initially passed in to the `ValueParser` constructor.
    /// The `ConversionStep` will return a `ExtractError.BadFormat` if parsing fails.
    public func asInt() -> ConversionStep<String, Int> {
        func typeName(_ stringLoader: StringLoader) -> String {
             return stringLoader("Flue.Extract.Type.Integer", "Flue: Extract value as Integer: Type description")
        }

        func convert(_ s: String, ctx: ConversionContext) -> ConversionResult<Int> {
            guard let parsed = ctx.valueParser.integerFormatter.number(from: s) else {
                return .failure(ctx.errorBuilder.badFormat(ctx.originalValue.name, value: s, expectType: typeName(ctx.stringLoader)))
            }
            return .success(parsed as Int)
        }
        func help(_ ctx: ConversionContext) -> [String] {
            return self.help(ctx) + [typeName(ctx.stringLoader)]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    /// Creates a `ConversionStep` that parses the input string as a double, using the locale initially passed in to the `ValueParser` constructor.
    /// The `ConversionStep` will return a `ExtractError.BadFormat` if parsing fails.
    public func asDouble() -> ConversionStep<String, Double> {
        func typeName(_ stringLoader: StringLoader) -> String {
            return stringLoader("Flue.Extract.Type.Double", "Flue: Extract value as Double: Type description")
        }

        func convert(_ s: String, ctx: ConversionContext) -> ConversionResult<Double> {
            guard let parsed = ctx.valueParser.floatFormatter.number(from: s) else {
                return .failure(ctx.errorBuilder.badFormat(ctx.originalValue.name, value: s, expectType: typeName(ctx.stringLoader)))
            }
            return .success(parsed as Double)
        }
        func help(_ ctx: ConversionContext) -> [String] {
            return self.help(ctx) + [typeName(ctx.stringLoader)]
        }

        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    /// Creates a `ConversionStep` that parses the input string as a boolean, using `NSString`'s `boolValue` method.
    public func asBool() -> ConversionStep<String, Bool> {
        func convert(_ s: String, ctx: ConversionContext) -> ConversionResult<Bool> {
            let bval = (s as NSString).boolValue
            return .success(bval)
        }

        func help(_ ctx: ConversionContext) -> [String] {
            return self.help(ctx) + [ctx.stringLoader("Flue.Extract.Type.Bool", "Flue: Extract value as Boolean: Help text")]
        }

        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    public func asDate(_ df: DateFormatter) -> ConversionStep<String, Date> {
        func convert(_ s: String, ctx: ConversionContext) -> ConversionResult<Date> {
            if let parsed = df.date(from: s) {
                return .success(parsed)
            }
            return .failure(ctx.errorBuilder.dateBadFormat(ctx.originalValue.name, value: s, format: df.dateFormat))
        }

        func help(_ ctx: ConversionContext) -> [String] {
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
    public func greaterThan(_ limit: Double) -> ConversionStep<Double, Double> {
        func convert(_ d: Double, ctx: ConversionContext) -> ConversionResult<Double> {
            if d > limit {
                return .success(d)
            }
            return .failure(ctx.errorBuilder.valueTooSmall(
                ctx.originalValue.name,
                value: ctx.originalValue.value!,
                shouldBeGreaterThan: ctx.valueParser.floatFormatter.string(from: NSNumber(value: limit))!))

        }
        func help(_ ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                ctx.stringLoader("Flue.Checks.Double.GreaterThan.Help", "Flue: Check double is greater than value: Help text. Parameters: limit"), ctx.valueParser.floatFormatter.string(from: NSNumber(value: limit))!)
            return self.help(ctx) + [msg]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    /**
     Creates a `ConversionStep` that checks that the input double is less than `limit`.

     - Parameter limit: The upper non-inclusive bound for the value.
     */
    public func lessThan(_ limit: Double) -> ConversionStep<Double, Double> {
        func convert(_ d: Double, ctx: ConversionContext) -> ConversionResult<Double> {
            if d < limit {
                return .success(d)
            }
            return .failure(ctx.errorBuilder.valueTooLarge(
                ctx.originalValue.name,
                value: ctx.originalValue.value!,
                shouldBeLessThan: ctx.valueParser.floatFormatter.string(from: NSNumber(value: limit))!))

        }
        func help(_ ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                ctx.stringLoader("Flue.Checks.Double.LessThan.Help", "Flue: Check double is less than value: Help text. Parameters: limit"), ctx.valueParser.floatFormatter.string(from: NSNumber(value: limit))!)
            return self.help(ctx) + [msg]
        }
        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }
}

extension ConversionStepProtocol where Output == Date {
    public func before(_ limit: Date) -> ConversionStep<Date, Date> {
        func convert(_ d: Date, ctx: ConversionContext) -> ConversionResult<Date> {
            if d < limit {
                return .success(d)
            }
            return .failure(ctx.errorBuilder.dateTooLate(
                ctx.originalValue.name,
                value: d,
                limit: limit))

        }
        func help(_ ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                ctx.stringLoader("Flue.Checks.NSDate.Before.Help", "Flue: Check NSDate is before another date: Help text. Parameters: limit"), ctx.valueParser.dateFormatter.string(from: limit))
            return self.help(ctx) + [msg]
        }

        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }

    public func after(_ limit: Date) -> ConversionStep<Date, Date> {
        func convert(_ d: Date, ctx: ConversionContext) -> ConversionResult<Date> {
            if d > limit {
                return .success(d)
            }
            return .failure(ctx.errorBuilder.dateTooEarly(
                ctx.originalValue.name,
                value: d,
                limit: limit))

        }
        func help(_ ctx: ConversionContext) -> [String] {
            let msg = String(format: 
                ctx.stringLoader("Flue.Checks.NSDate.After.Help", "Flue: Check NSDate is after another date: Help text. Parameters: limit"), ctx.valueParser.dateFormatter.string(from: limit))
            return self.help(ctx) + [msg]
        }

        return ConversionStep(input: self.readValue, convert: convert, help: help, context: self.context)
    }
}

internal func flueBundle() -> Bundle {
    return Bundle(for: ValueParser.self)
}
