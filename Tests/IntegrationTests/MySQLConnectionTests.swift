import Logging
import MySQLNIO
import NIOCore
import NIOSSL
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@Suite("MySQLConnection Tests")
struct MySQLConnectionTests {
    let mySQLHostname = ProcessInfo.processInfo.environment["MYSQL_HOSTNAME"] ?? "localhost"

    @Test("Select Version")
    func selectVersion() async throws {
        try await MySQLConnection.withConnection(
            address: .hostname(mySQLHostname),
            configuration: .init(username: "test_username", password: "test_password"),
            logger: logger
        ) { connection in
            try await connection.query("SELECT @@version") { rows in
                for try await row in rows {
                    for cell in row {
                        let version = String(buffer: try #require(cell.bytes))
                        #expect(version.contains("."))
                    }
                }
            }
        }
    }

    @Test("Select String")
    func selectString() async throws {
        try await MySQLConnection.withConnection(
            address: .hostname(mySQLHostname),
            configuration: .init(username: "test_username", password: "test_password"),
            logger: logger
        ) { connection in
            try await connection.query("SELECT 'foo' as bar") { rows in
                for try await row in rows {
                    for cell in row {
                        #expect(cell.columnName == "bar")
                        let value = String(buffer: try #require(cell.bytes))
                        #expect(value == "foo")
                    }
                }
            }
        }
    }

    @Test("Select Integers")
    func selectIntegers() async throws {
        try await MySQLConnection.withConnection(
            address: .hostname(mySQLHostname),
            configuration: .init(username: "test_username", password: "test_password"),
            logger: logger
        ) { connection in
            try await connection.query("SELECT '1' as one, 2 as two") { rows in
                for try await row in rows {
                    for cell in row {
                        let value = String(buffer: try #require(cell.bytes))
                        switch cell.columnName {
                        case "one": #expect(value == "1")
                        case "two": #expect(value == "2")
                        default: Issue.record()
                        }
                    }
                }
            }
        }
    }

    @Test("No Response")
    func noResponse() async throws {
        try await MySQLConnection.withConnection(
            address: .hostname(mySQLHostname),
            configuration: .init(username: "test_username", password: "test_password"),
            logger: logger
        ) { connection in
            try await connection.query("SET @foo = 'bar'") { rows in
                var iterator = rows.makeAsyncIterator()
                let firstRow = try await iterator.next()
                #expect(firstRow == nil)
            }
        }
    }

    @Test("Ping")
    func ping() async throws {
        try await MySQLConnection.withConnection(
            address: .hostname(mySQLHostname),
            configuration: .init(username: "test_username", password: "test_password"),
            logger: logger
        ) { connection in
            try await connection.ping()
        }
    }

    @Test("Reset Connection")
    func resetConnection() async throws {
        try await MySQLConnection.withConnection(
            address: .hostname(mySQLHostname),
            configuration: .init(username: "test_username", password: "test_password"),
            logger: logger
        ) { connection in
            try await connection.resetConnection()
        }
    }

    @Test("Init Database")
    func initDB() async throws {
        try await MySQLConnection.withConnection(
            address: .hostname(mySQLHostname),
            configuration: .init(username: "test_username", password: "test_password"),
            logger: logger
        ) { connection in
            try await connection.initDB(schema: "test_database")
        }
    }

    @Test("Statistics")
    func statistics() async throws {
        try await MySQLConnection.withConnection(
            address: .hostname(mySQLHostname),
            configuration: .init(username: "test_username", password: "test_password"),
            logger: logger
        ) { connection in
            let stats = try await connection.statistics()
            #expect(stats.contains("Uptime: "))
        }
    }

    @Test("Connect with TLS", .disabled(if: ProcessInfo.processInfo.environment["CI"] != nil, "TODO: setup TLS testing in CI"))
    func tlsConnect() async throws {
        try await MySQLConnection.withConnection(
            address: .hostname(mySQLHostname),
            configuration: .init(
                username: "test_username",
                password: "test_password",
                tls: .prefer(try Self.sslContext, tlsServerName: "vapor.codes")
            ),
            logger: logger
        ) { connection in
            try await connection.ping()
        }
    }

    static var sslContext: NIOSSLContext {
        get throws {
            let rootCertificate = try NIOSSLCertificate.fromPEMFile(Self.rootPath + "/Certs/ca.pem")
            let certificate = try NIOSSLCertificate.fromPEMFile(Self.rootPath + "/Certs/client.pem")
            let privateKey = try NIOSSLPrivateKey(file: Self.rootPath + "/Certs/client.key", format: .pem)
            var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
            tlsConfiguration.trustRoots = .certificates(rootCertificate)
            tlsConfiguration.certificateChain = certificate.map { .certificate($0) }
            tlsConfiguration.privateKey = .privateKey(privateKey)
            return try NIOSSLContext(configuration: tlsConfiguration)
        }
    }

    static let rootPath = #filePath
        .split(separator: "/", omittingEmptySubsequences: false)
        .dropLast(3)
        .joined(separator: "/")

    let logger: Logger = {
        var logger = Logger(label: "MySQLNIOTests")
        logger.logLevel = .trace
        return logger
    }()
}
