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
    func testExtract_required_string_is_found_no_error() {
        let env = ["asdf": "fdsa"]
        let v = try! ValueParser(env: env).extract("asdf").required()
        XCTAssertEqual(v, "fdsa")
    }

    func testExtract_required_string_is_not_found_error() {
        let env = ["asdf": "fdsa"]
        do {
            let _ = try ValueParser(env: env).extract("qwer").required()
        } catch ExtractError.ValueMissing(let name) {
            XCTAssertEqual(name, "qwer")
            return
        } catch let err {
            XCTFail("Unexpected exception \(err)")
            return
        }
        XCTFail("Expected an exception")
    }

    func testExtract_required_int_is_found() {
        let env = ["asdf": "1"]
        let value: Int = try! ValueParser(env: env).extract("asdf").asInt().required()
        XCTAssertEqual(value, 1)
    }

    func testExtract_required_int_is_not_found_error() {
        let env = ["asdf": "1"]
        do {
            let _ = try ValueParser(env: env).extract("qwer").asInt().required()
        } catch ExtractError.CollectedErrors(let errs) {
            XCTAssertEqual(errs.count, 1)
            if case let ExtractError.ValueMissing(name: name) = errs[0] {
                XCTAssertEqual(name, "qwer")
            }
            return
        } catch let err {
            XCTFail("Unexpected exception \(err)")
            return
        }
        XCTFail("Expected an exception")
    }

    func testExtract_required_int_is_not_int_error() {
        let env = ["asdf": "notint"]
        do {
            let _ = try ValueParser(env: env).extract("asdf").asInt().required()
        } catch ExtractError.CollectedErrors(let errs) {
            XCTAssertEqual(errs.count, 1)
            print("errs: \(errs)")
            XCTAssertEqual(errs[0], ExtractError.FormatError(name: "asdf", value: "notint", expectType: "Integer"))
            return
        } catch let err {
            XCTFail("Unexpected exception \(err)")
            return
        }
        XCTFail("Expected an exception")
    }

    func testExtract_missing_value_replaced_by_default_value() {
        let env = ["asdf": "notint"]
        let value = try! ValueParser(env: env).extract("qwer").asInt().defaultValue(6)
        XCTAssertEqual(value, 6)
    }

    func testExtract_default_value_int_is_not_int_error() {
        let env = ["asdf": "notint"]
        do {
            let _ = try ValueParser(env: env).extract("asdf").asInt().defaultValue(12)
        } catch ExtractError.CollectedErrors(let errs) {
            XCTAssertEqual(errs.count, 1)
            if case let ExtractError.FormatError(name, value, expectType) = errs[0] {
                XCTAssertEqual(name, "asdf")
                XCTAssertEqual(value, "notint")
                XCTAssertEqual(expectType, "Integer")
            }
            return
        } catch let err {
            XCTFail("Unexpected exception \(err)")
            return
        }
        XCTFail("Expected an exception")
    }

    func testExtract_bool_values() {
        let env = ["1": "Y", "2": "y", "3": "yeeeees", "4": "true", "5": "TRUE", "6": "n", "7": "m", "8": "f"]
        let vp = ValueParser(env: env)
        XCTAssertTrue(try! vp.extract("1").asBool().required())
        XCTAssertTrue(try! vp.extract("2").asBool().required())
        XCTAssertTrue(try! vp.extract("3").asBool().required())
        XCTAssertTrue(try! vp.extract("4").asBool().required())
        XCTAssertTrue(try! vp.extract("5").asBool().required())

        XCTAssertFalse(try! vp.extract("6").asBool().required())
        XCTAssertFalse(try! vp.extract("7").asBool().required())
        XCTAssertFalse(try! vp.extract("8").asBool().required())
    }

    func testExtract_int_range_value_good() {
        let env = ["asdf": "5"]
        let v = try! ValueParser(env: env).extract("asdf").asInt().range(1...10).required()
        XCTAssertEqual(v, 5)
    }

    func testExtract_int_range_value_outside_range() {
        let env = ["asdf": "15"]
        do {
            try ValueParser(env: env).extract("asdf").asInt().range(1...10).required()
        } catch ExtractError.CollectedErrors(let ec) {
            XCTAssertEqual(ec.count, 1)
            XCTAssertEqual(ec.first, ExtractError.IntRangeError(name: "asdf", value: 15, range: 1...10))
            return
        } catch {
            XCTFail("Unexpected exception \(error)")
            return
        }
        XCTFail("Expected an exception")
    }

    func testExtract_int_range_value_not_int() {
        let env = ["asdf": "qwer"]
        do {
            try ValueParser(env: env).extract("asdf").asInt().range(1...10).required()
        } catch ExtractError.CollectedErrors(let ec) {
            XCTAssertEqual(ec.count, 1)
//            XCTAssertEqual(ec.first, ExtractError.FormatError(name: <#T##String#>, value: <#T##String#>, problem: <#T##String#>)
            return
        } catch {
            XCTFail("Unexpected exception \(error)")
            return
        }
        XCTFail("Expected an exception")
    }

}
