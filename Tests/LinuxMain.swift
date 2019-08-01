import XCTest

import MySQLNIOTests

var tests = [XCTestCaseEntry]()
tests += MySQLNIOTests.__allTests()

XCTMain(tests)
