//
//  FlueTests.swift
//  FlueTests
//
//  Created by Juri Pakaste on 09/02/16.
//  Copyright © 2016 Juri Pakaste. All rights reserved.
//

import XCTest
import Flue

class FlueTests: XCTestCase {
    func testDF() {
        let df = DateFormatter()
        df.dateFormat = "H:mm"
        let d = df.date(from: "16:31")!
        print("d: ", d)
    }

    func testValueReader_Numbers() {
        let env = ["asdf": "1", "d": "1.2345"]
        let vp = DictParser(dict: env)
        XCTAssertEqual(try! vp.extract("asdf").asInt().required(), 1)
        XCTAssertEqual(try! vp.extract("asdf").asInt().range(0...5).required(), 1)
        XCTAssertEqual(vp.extract("asdf").asInt().range(2...5).defaultValue(2), 2)
        XCTAssertEqual(vp.extract("zap").asInt().range(2...5).defaultValue(2), 2)
        XCTAssertEqual(vp.extract("zap").asInt().defaultValue(2), 2)
        XCTAssertNil(vp.extract("asdf").asInt().range(2...5).optional())
        XCTAssertEqualWithAccuracy(try! vp.extract("d").asDouble().required(), 1.2345, accuracy: 0.00001)
        XCTAssertNil(vp.extract("d").asInt().optional())

        do {
            let _ = try vp.extract("zap").asInt().required()
            XCTFail("Expected an exception")
        } catch let ExtractError.valueMissing(name, _) {
            XCTAssertEqual(name, "zap")
        } catch {
            XCTFail("Unexpected exception \(error)")
            return
        }
        do {
            let _ = try vp.extract("asdf").asInt().range(10...20).required()
            XCTFail("Expected an exception")
        } catch let ExtractError.intNotInRange(name, value, range, _) {
            XCTAssertEqual(name, "asdf")
            XCTAssertEqual(value, 1)
            XCTAssertEqual(range, 10...20)
        } catch {
            XCTFail("Unexpected exception \(error)")
            return
        }
    }

    func testValueReader_Numbers_With_Locale() {
        let env = ["i1": "1", "d1": "1.2345", "d2": "2,3456"]
        let vp = DictParser(dict: env, valueParser: ValueParser(locale: Locale(identifier: "fi_FI")))
        XCTAssertEqual(try! vp.extract("i1").asInt().required(), 1)
        XCTAssertNil(vp.extract("d1").asDouble().optional())
        XCTAssertEqualWithAccuracy(try! vp.extract("d2").asDouble().required(), 2.3456, accuracy: 0.00001)
        XCTAssertNil(vp.extract("d1").asInt().optional())
        XCTAssertNil(vp.extract("d2").asInt().optional())
    }

    func testValueReader_Double_limits() {
        let env = ["d1": "1.2345"]
        let dp = DictParser(dict: env)
        XCTAssertEqualWithAccuracy(try! dp.extract("d1").asDouble().greaterThan(1.2344).lessThan(1.2346).required(), 1.2345, accuracy: 0.00001)
        XCTAssertNil(dp.extract("d1").asDouble().greaterThan(1.2346).optional())
        XCTAssertNil(dp.extract("d1").asDouble().lessThan(1.2344).optional())
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

    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int, _ timeZone: TimeZone) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = minute
        comps.second = second
        comps.timeZone = timeZone
        comps.calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        return comps.date!
    }

    func testValueReader_Date() {
        let env = ["date1": "2016-03-21T17:33:00+02:00"]
        let dp = DictParser(dict: env)
        let df = DateFormatter()
        df.calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        df.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZZZ"
        let tz = TimeZone(secondsFromGMT: 60 * 60 * 2)!
        XCTAssertEqualWithAccuracy(try! dp.extract("date1").asDate(df).after(date(2016, 03, 21, 17, 32, 0, tz)).before(date(2016, 03, 21, 17, 34, 0, tz)).required().timeIntervalSinceReferenceDate, date(2016, 03, 21, 17, 33, 0, tz).timeIntervalSinceReferenceDate, accuracy: 1)
    }

    func testHelp() {
        let vp = DictParser(dict: ["q": "12"])
        XCTAssertEqual(vp.extract("a").asInt().usage(), ["a", "Integer"])
        XCTAssertEqual(vp.extract("a").asInt().range(1...10).usage(), ["a", "Integer", "Range: 1...10"])
        XCTAssertEqual(vp.extract("a").asBool().usage(), ["a", "Boolean: true if string starts with [YyTt1-9]"])
        XCTAssertEqual(vp.extract("a").asBool().addHelp("Usage string").usage(), ["a", "Boolean: true if string starts with [YyTt1-9]", "Usage string"])
        XCTAssertEqual(vp.extract("a").addHelp("Foo", prefix: true).usage(), ["Foo", "a"])
        XCTAssertEqual(vp.extract("a").addHelp("Bar").addHelp("Foo", prefix: true).usage(), ["a", "Foo", "Bar"])

        let c = vp.extract("q").asInt()
        let cv = try! c.required()
        XCTAssertEqual(c.usage(), ["q", "Integer"])
        XCTAssertEqual(cv, 12)
    }

    func testString() {
        let vp = DictParser(dict: ["q": "w"])
        XCTAssertEqual(try! vp.extract("q").required(), "w")
    }

    func testJSONWithFullConvert() {
        let vp = DictParser(dict: ["q": "{\"w\": 1}"])
        func convert(_ v: Any, ctx: ConversionContext) -> ConversionResult<[String: Int]> {
            if let vd = v as? [String: Int] {
                return .success(vd)
            }
            return .failure(ExtractError.otherError("Can't convert value \(v) to dict"))
        }
        let j = try! vp.extract("q").asJSON().asType(convert, help: "plerp").required()
        XCTAssertEqual(j, ["w": 1])
    }

    func testJSONWithOptionalConvert() {
        let vp = DictParser(dict: ["q": "{\"w\": 1}"])
        func convert(_ v: Any, ctx: ConversionContext) -> [String: Int]? {
            return v as? [String: Int]
        }
        let j = try! vp.extract("q").asJSON().asType(convert, help: "plerp").required()
        XCTAssertEqual(j, ["w": 1])
    }

    func testJSONWithOptionalConvertFailure() {
        let vp = DictParser(dict: ["q": "{\"w\": \"e\"}"])
        func convert(_ v: Any, ctx: ConversionContext) -> [String: Int]? {
            return v as? [String: Int]
        }
        do {
            let _ = try vp.extract("q").asJSON().asType(convert).required()
            XCTFail("Expected an exception")
        } catch let ExtractError.badFormat(name, value, expectType, _) {
            XCTAssertEqual(name, "q")
            XCTAssertEqual(value, "{\"w\": \"e\"}")
            XCTAssertEqual(expectType, "Dictionary<String, Int>")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testJSONWithOptionalConvertHelp() {
        let vp = DictParser(dict: ["q": "{\"w\": \"e\"}"])
        func convert(_ v: Any, ctx: ConversionContext) -> [String: Int]? {
            return v as? [String: Int]
        }
        let help = vp.extract("q").asJSON().asType(convert).usage()
        XCTAssertEqual(help, ["q", "JSON Data", "Type: Dictionary<String, Int>"])
    }

    func testStringLength() {
        let vp = DictParser(dict: ["q": "wer"])

        switch vp.extract("q").minLength(1).readValue() {
        case .success(let v):
            XCTAssertEqual(v, "wer")
        case .failure(let e):
            XCTFail("Unexpected error \(e)")
        }

        switch vp.extract("q").minLength(4).readValue() {
        case .success(let v):
            XCTFail("Unexpected success \(v)")
        case .failure(let e as ExtractError):
            XCTAssertEqual(e, ExtractError.stringTooShort(name: "q", value: "wer", minLength: 4, localizedDescription: ""))
        case .failure(let e):
            XCTFail("Unexpected error \(e)")
        }

        switch vp.extract("q").maxLength(4).readValue() {
        case .success(let v):
            XCTAssertEqual(v, "wer")
        case .failure(let e):
            XCTFail("Unexpected error \(e)")
        }

        switch vp.extract("q").maxLength(2).readValue() {
        case .success(let v):
            XCTFail("Unexpected success \(v)")
        case .failure(let e as ExtractError):
            XCTAssertEqual(e, ExtractError.stringTooLong(name: "q", value: "wer", maxLength: 2, localizedDescription: ""))
        case .failure(let e):
            XCTFail("Unexpected error \(e)")
        }
    }

    func testRegexp() {
        let dp = DictParser(dict: ["q": "asdf"])

        switch dp.extract("q").regexp("a.*")!.readValue() {
        case .success(let v):
            XCTAssertEqual(v, "asdf")
        case .failure(let e):
            XCTFail("Unexpected error \(e)")
        }

        switch dp.extract("q").regexp("b.*")!.readValue() {
        case .success(let v):
            XCTFail("Unexpected value \(v)")
        case .failure(let e as ExtractError):
            XCTAssertEqual(e, ExtractError.noRegexpMatch(name: "q", value: "asdf", regexp: "b.*", localizedDescription: ""))
        case .failure(let e):
            XCTFail("Unexpected error \(e)")
        }
    }
}
