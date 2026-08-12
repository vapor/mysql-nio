import Testing

@testable import MySQLNIO

@Suite("MySQLNIO Tests")
struct MySQLNIOTests {
    @Test("Best Collation for Version")
    func bestCollationForVersion() {
        let mariaDBVersions: [String: MySQLCollation] = [
            // MariaDB 10.9 or older
            "9.0": .utf8Unicode52CI,
            "10.0": .utf8Unicode52CI,
            "10.6": .utf8Unicode52CI,
            // MariaDB 10.10 or newer
            "10.10": .utf8Unicode14AICI,
            "10.11": .utf8Unicode14AICI,
            "11.8": .utf8Unicode14AICI,
            "12.3": .utf8Unicode14AICI,
            "13.0": .utf8Unicode14AICI,
            "14.0": .utf8Unicode14AICI,
        ]

        let mySQLVersions: [String: MySQLCollation] = [
            // MySQL 5.7 or older
            "5.0": .utf8Unicode52CI,
            "5.7": .utf8Unicode52CI,
            "6.0": .utf8Unicode52CI,
            "7.0": .utf8Unicode52CI,
            // MySQL 8.0 or newer
            "8.4": .utf8Unicode9AICI,
            "9.7": .utf8Unicode9AICI,
            "10.0": .utf8Unicode9AICI,
            "11.0": .utf8Unicode9AICI,
            "26.7": .utf8Unicode9AICI,
            "27.0": .utf8Unicode9AICI,
            "28.0": .utf8Unicode9AICI,
            "30.0": .utf8Unicode9AICI,
        ]

        for (version, expectedCollation) in mariaDBVersions {
            let actualCollation = MySQLCollation.bestCollation(forVersion: version, capabilities: .init())
            #expect(actualCollation == expectedCollation, "Expected \(expectedCollation) for MariaDB version \(version), but got \(actualCollation)")
        }
        for (version, expectedCollation) in mySQLVersions {
            let actualCollation = MySQLCollation.bestCollation(forVersion: version, capabilities: .clientMySQL)
            #expect(actualCollation == expectedCollation, "Expected \(expectedCollation) for MySQL version \(version), but got \(actualCollation)")
        }
    }
}
