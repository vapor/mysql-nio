import NIOCore
import Testing

@testable import MySQLNIO

// Command for DDL/DML that expects OK packets, supports multi-statement
private final class MySQLExecuteCommand: MySQLCommand, @unchecked Sendable {
  let sql: String

  init(_ sql: String) {
    self.sql = sql
  }

  func activate(capabilities: MySQLProtocol.CapabilityFlags) throws -> MySQLCommandState {
    try .response([.encode(MySQLProtocol.COM_QUERY(query: sql), capabilities: capabilities)])
  }

  func handle(packet: inout MySQLPacket, capabilities: MySQLProtocol.CapabilityFlags) throws
    -> MySQLCommandState
  {
    if packet.isError {
      let err = try packet.decode(MySQLProtocol.ERR_Packet.self, capabilities: capabilities)
      throw MySQLError.server(err)
    }

    let ok = try MySQLProtocol.OK_Packet.decode(from: &packet, capabilities: capabilities)
    if ok.statusFlags.contains(.SERVER_MORE_RESULTS_EXISTS) {
      return .noResponse  // more OK packets coming
    }
    return .done
  }
}

extension MySQLDatabase {
  func execute(_ sql: String) -> EventLoopFuture<Void> {
    send(MySQLExecuteCommand(sql), logger: logger)
  }
}

@Suite(.serialized)
struct SpRowsTests {
  init() {
    #expect(isLoggingConfigured)
  }

  @Test
  func executeErrorHandling() async throws {
    let conn = try await MySQLConnection.test()

    // Valid statement succeeds (DO is a no-op that returns OK)
    try await conn.execute("DO 1").get()

    // Invalid statement throws error
    do {
      try await conn.execute("INVALID SQL SYNTAX").get()
      #expect(Bool(false), "Expected error for invalid SQL")
    } catch let error as MySQLError {
      if case .server(let errPacket) = error {
        #expect(errPacket.errorCode == .PARSE_ERROR)
      } else {
        #expect(Bool(false), "Expected server error, got \(error)")
      }
    }

    try await conn.close().get()
  }

  @Test
  func setupAndVerifyData() async throws {
    let conn = try await MySQLConnection.test()

    do {
      try await conn.execute(
        """
        CREATE OR REPLACE TABLE kv (
            id INT AUTO_INCREMENT PRIMARY KEY,
            value VARCHAR(255) NOT NULL UNIQUE
        )
        """
      ).get()

      try await conn.execute(
        """
        CREATE OR REPLACE PROCEDURE sp_add_kv_val(IN p_value varchar(255))
        BEGIN
            INSERT INTO kv (value) VALUES (p_value);
        END
        """
      ).get()

      try await conn.execute(
        """
        CREATE OR REPLACE PROCEDURE sp_find_kv_by_val(IN p_prefix varchar(255))
        BEGIN
            SELECT id, value FROM kv WHERE value LIKE CONCAT(p_prefix, '%');
        END
        """
      ).get()

      try await conn.execute(
        """
        START TRANSACTION;
        CALL sp_add_kv_val('example1');
        CALL sp_add_kv_val('example2');
        CALL sp_add_kv_val('example3');
        CALL sp_add_kv_val('example4');
        COMMIT
        """
      ).get()

      // Verify data exists with simple SELECT
      let rows = try await conn.simpleQuery("SELECT id, value FROM kv WHERE value LIKE 'example%'")
        .get()
      #expect(rows.count == 4)

      // Test stored procedure returning rows
      let spRows = try await conn.simpleQuery("CALL sp_find_kv_by_val('example')").get()
      #expect(spRows.count == 4)

      // Test stored procedure returning zero rows
      let noRows = try await conn.simpleQuery("CALL sp_find_kv_by_val('notavailable')").get()
      #expect(noRows.count == 0)

      // Cleanup
      try await conn.execute("DROP TABLE IF EXISTS kv").get()
    } catch {
      try? await conn.execute("DROP TABLE IF EXISTS kv").get()
      try? await conn.close().get()
      throw error
    }
    try await conn.close().get()
  }
}
