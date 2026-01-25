import MySQLNIO
import Testing

// Test helpers
private func setupKvTable(_ conn: MySQLConnection) async throws {
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
}

private func cleanupKvTable(_ conn: MySQLConnection) async {
  try? await conn.execute("DROP TABLE IF EXISTS kv").get()
}

// Use this to have the initial test environment
private func withKvTestConnection(_ body: (MySQLConnection) async throws -> Void) async throws {
  let conn = try await MySQLConnection.test()
  do {
    try await setupKvTable(conn)
    try await body(conn)
    await cleanupKvTable(conn)
  } catch {
    await cleanupKvTable(conn)
    try? await conn.close().get()
    throw error
  }
  try await conn.close().get()
}

@Suite(.serialized)
struct MultiResultTests {
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
      if case .invalidSyntax(let message) = error {
        #expect(message.contains("syntax"))
      } else {
        #expect(Bool(false), "Expected invalidSyntax error, got \(error)")
      }
    }

    try await conn.close().get()
  }

  @Test
  func storedProcedureReturnsRows() async throws {
    try await withKvTestConnection { conn in
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
    }
  }

  @Test
  func transactionRollbackOnConstraintViolation() async throws {
    try await withKvTestConnection { conn in
      // Insert initial data
      try await conn.execute("CALL sp_add_kv_val('initial')").get()

      // Verify initial state
      let before = try await conn.simpleQuery("SELECT COUNT(*) as cnt FROM kv").get()
      #expect(before[0].column("cnt")?.int == 1)

      // Try transaction with duplicate - should fail
      do {
        try await conn.execute(
          """
          START TRANSACTION;
          CALL sp_add_kv_val('example11');
          CALL sp_add_kv_val('example22');
          CALL sp_add_kv_val('example33');
          CALL sp_add_kv_val('example33');
          COMMIT
          """
        ).get()
        #expect(Bool(false), "Expected duplicate key error")
      } catch let error as MySQLError {
        switch error {
        case .duplicateEntry(let message):
          #expect(message.contains("Duplicate"))
        default:
          #expect(Bool(false), "Unexpected error type: \(error)")
        }
      }

      // Rollback explicitly in case transaction is still open
      try? await conn.execute("ROLLBACK").get()

      // Verify table unchanged - should still have only 'initial'
      let after = try await conn.simpleQuery("SELECT COUNT(*) as cnt FROM kv").get()
      #expect(after[0].column("cnt")?.int == 1)
    }
  }
}
