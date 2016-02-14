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
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExtract_required_string_is_found_no_error() {
        let env = ["asdf": "fdsa"]
        let v = try! extractFrom(env, key: "asdf").required()
        XCTAssertEqual(v, "fdsa")
    }

    func testExtract_required_string_is_not_found_error() {
        let env = ["asdf": "fdsa"]
        do {
            let _ = try extractFrom(env, key: "qwer").required()
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
        let value: Int = try! extractFrom(env, key: "asdf").asInt().required()
        XCTAssertEqual(value, 1)
    }

    func testExtract_required_int_is_not_found_error() {
        let env = ["asdf": "1"]
        do {
            let _ = try extractFrom(env, key: "qwer").asInt().required()
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
            let _ = try extractFrom(env, key: "asdf").asInt().required()
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
        let value = try! extractFrom(env, key: "qwer").asInt().defaultValue(6)
        XCTAssertEqual(value, 6)
    }

    func testExtract_default_value_int_is_not_int_error() {
        let env = ["asdf": "notint"]
        do {
            let _ = try extractFrom(env, key: "asdf").asInt().defaultValue(12)
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

}
