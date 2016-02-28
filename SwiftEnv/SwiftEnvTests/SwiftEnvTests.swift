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
        let vp = ValueParser(env: env)
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

}
