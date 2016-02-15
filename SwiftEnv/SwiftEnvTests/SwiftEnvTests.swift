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
        } catch ExtractError.ValueMissing(let name) {
            XCTAssertEqual(name, "qwer")
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
        } catch ExtractError.FormatError(let name, let value) {
            XCTAssertEqual(name, "asdf")
            XCTAssertEqual(value, "notint")
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
        } catch ExtractError.FormatError(let name, let value) {
            XCTAssertEqual(name, "asdf")
            XCTAssertEqual(value, "notint")
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
}
