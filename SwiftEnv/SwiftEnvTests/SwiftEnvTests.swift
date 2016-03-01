//
//  SwiftEnvTests.swift
//  SwiftEnvTests
//
//  Created by Juri Pakaste on 09/02/16.
//  Copyright © 2016 Juri Pakaste. All rights reserved.
//

import XCTest
@testable import SwiftEnv

class SwiftEnvTests: XCTestCase {
    func testValueReader() {
        let env = ["asdf": "1"]
        let vp = DictParser(dict: env)
        XCTAssertEqual(try! vp.extract("asdf").asInt().required(), 1)
        XCTAssertEqual(try! vp.extract("asdf").asInt().range(0...5).required(), 1)
        XCTAssertEqual(vp.extract("asdf").asInt().range(2...5).defaultValue(2), 2)
        XCTAssertEqual(vp.extract("zap").asInt().range(2...5).defaultValue(2), 2)
        XCTAssertEqual(vp.extract("zap").asInt().defaultValue(2), 2)
        XCTAssertNil(vp.extract("asdf").asInt().range(2...5).optional())
        do {
            try vp.extract("zap").asInt().required()
            XCTFail("Expected an exception")
        } catch let ExtractError.ValueMissing(name) {
            XCTAssertEqual(name, "zap")
        } catch {
            XCTFail("Unexpected exception \(error)")
            return
        }
        do {
            try vp.extract("asdf").asInt().range(10...20).required()
            XCTFail("Expected an exception")
        } catch let ExtractError.IntRangeError(name, value, range) {
            XCTAssertEqual(name, "asdf")
            XCTAssertEqual(value, 1)
            XCTAssertEqual(range, 10...20)
        } catch {
            XCTFail("Unexpected exception \(error)")
            return
        }
    }

    func testValueReader_Bool() {
        let env = ["1": "Y", "2": "y", "3": "yeeeees", "4": "true", "5": "TRUE", "6": "n", "7": "m", "8": "f"]
        let vp = DictParser(dict: env)
        XCTAssertTrue(try! vp.extract("1").asBool().required())
        XCTAssertTrue(try! vp.extract("2").asBool().required())
        XCTAssertTrue(try! vp.extract("3").asBool().required())
        XCTAssertTrue(try! vp.extract("4").asBool().required())
        XCTAssertTrue(try! vp.extract("5").asBool().required())

        XCTAssertFalse(try! vp.extract("6").asBool().required())
        XCTAssertFalse(try! vp.extract("7").asBool().required())
        XCTAssertFalse(try! vp.extract("8").asBool().required())
    }

    func testHelp() {
        let vp = DictParser(dict: ["q": "12"])
        XCTAssertEqual(vp.extract("a").asInt().help(), ["Name: a", "Integer"])
        XCTAssertEqual(vp.extract("a").asInt().range(1...10).help(), ["Name: a", "Integer", "Range: 1..<11"])
        XCTAssertEqual(vp.extract("a").asBool().help(), ["Name: a", "True if string starts with [YyTt1-9]"])
        XCTAssertEqual(vp.extract("a").asBool().usage("Usage string"), ["Name: a", "True if string starts with [YyTt1-9]", "Usage string"])
        XCTAssertEqual(vp.extract("a").asString().help(), ["Name: a", "String"])

        let c = vp.extract("q").asInt()
        let cv = try! c.required()
        XCTAssertEqual(c.help(), ["Name: q", "Integer"])
        XCTAssertEqual(cv, 12)
    }

    func testString() {
        let vp = DictParser(dict: ["q": "w"])
        XCTAssertEqual(try! vp.extract("q").asString().required(), "w")
    }

    func testJSONWithFullConvert() {
        let vp = DictParser(dict: ["q": "{\"w\": 1}"])
        func convert(v: AnyObject, ov: OriginalValue) -> ConversionResult<[String: Int], ExtractError> {
            if let vd = v as? [String: Int] {
                return .Success(vd)
            }
            return .Failure(ExtractError.OtherError("Can't convert value \(v) to dict"))
        }
        let j = try! vp.extract("q").asJSON().asType(convert, help: "plerp").required()
        XCTAssertEqual(j, ["w": 1])
    }

    func testJSONWithOptionalConvert() {
        let vp = DictParser(dict: ["q": "{\"w\": 1}"])
        func convert(v: AnyObject, ov: OriginalValue) -> [String: Int]? {
            return v as? [String: Int]
        }
        let j = try! vp.extract("q").asJSON().asType(convert, help: "plerp").required()
        XCTAssertEqual(j, ["w": 1])
    }

    func testJSONWithOptionalConvertFailure() {
        let vp = DictParser(dict: ["q": "{\"w\": \"e\"}"])
        func convert(v: AnyObject, ov: OriginalValue) -> [String: Int]? {
            return v as? [String: Int]
        }
        do {
            try vp.extract("q").asJSON().asType(convert).required()
            XCTFail("Expected an exception")
        } catch let ExtractError.FormatError(name, value, expectType) {
            XCTAssertEqual(name, "q")
            XCTAssertEqual(value, "{\"w\": \"e\"}")
            XCTAssertEqual(expectType, "Dictionary<String, Int>")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testJSONWithOptionalConvertHelp() {
        let vp = DictParser(dict: ["q": "{\"w\": \"e\"}"])
        func convert(v: AnyObject, ov: OriginalValue) -> [String: Int]? {
            return v as? [String: Int]
        }
        let help = vp.extract("q").asJSON().asType(convert).help()
        XCTAssertEqual(help, ["Name: q", "JSON Data", "Type: Dictionary<String, Int>"])
    }
}
