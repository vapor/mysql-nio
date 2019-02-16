import XCTest

import NIOMySQLTests

var tests = [XCTestCaseEntry]()
tests += NIOMySQLTests.allTests()
XCTMain(tests)
