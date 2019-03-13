import XCTest

import NIOMySQLTests

var tests = [XCTestCaseEntry]()
tests += NIOMySQLTests.__allTests()

XCTMain(tests)
