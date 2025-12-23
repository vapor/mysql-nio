<p align="center">
<img src="https://design.vapor.codes/images/vapor-mysqlnio.svg" height="96" alt="MySQLNIO">
<br>
<br>
<a href="https://docs.vapor.codes/4.0/"><img src="https://design.vapor.codes/images/readthedocs.svg" alt="Documentation"></a>
<a href="https://discord.gg/vapor"><img src="https://design.vapor.codes/images/discordchat.svg" alt="Team Chat"></a>
<a href="LICENSE"><img src="https://design.vapor.codes/images/mitlicense.svg" alt="MIT License"></a>
<a href="https://github.com/vapor/mysql-nio/actions/workflows/test.yml"><img src="https://img.shields.io/github/actions/workflow/status/vapor/mysql-nio/test.yml?event=push&style=plastic&logo=github&label=test&logoColor=%23ccc" alt="Continuous Integration"></a>
<a href="https://codecov.io/github/vapor/mysql-nio"><img src="https://img.shields.io/codecov/c/github/vapor/mysql-nio?style=plastic&logo=codecov&label=Codecov" alt="Codde Coverage"></a>
<a href="https://swift.org"><img src="https://design.vapor.codes/images/swift60up.svg" alt="Swift 6.0+"></a>
</p>

<br>

🐬 Non-blocking, event-driven Swift client for MySQL built on [SwiftNIO](https://github.com/apple/swift-nio).

## Using MySQLNIO

Use standard SwiftPM syntax to include MySQLNIO as a dependency in your `Package.swift` file.

```swift
.package(url: "https://github.com/vapor/mysql-nio.git", from: "1.0.0")
```

### Supported Platforms

MySQLNIO supports the following platforms:

- Ubuntu 20.04+
- macOS 10.15+
- iOS 13+
- tvOS 13+ and watchOS 7+ (experimental)

## Overview

MySQLNIO is a client package for connecting to, authorizing, and querying a MySQL server. At the heart of this module are NIO channel handlers for parsing and serializing messages in MySQL's proprietary wire protocol. These channel handlers are combined in a request / response style connection type that provides a convenient, client-like interface for performing queries. 

Support for both simple (text) and parameterized (prepared statement) querying is provided out of the box alongside a `MySQLData` type that handles conversion between MySQL's wire format and native Swift types.

### Motivation

Most Swift implementations of MySQL clients are based on the [libmysqlclient](https://dev.mysql.com/doc/c-api/5.7/en/c-api-implementations.html) C library which handles transport internally. Building a library directly on top of MySQL's wire protocol using SwiftNIO should yield a more reliable, maintainable, and performant interface for MySQL databases.

### Goals

This package is meant to be a low-level, unopinionated MySQL wire-protocol implementation for Swift. The hope is that higher level packages can share MySQLNIO as a foundation for interacting with MySQL servers without needing to duplicate complex logic.

Because of this, MySQLNIO excludes some important concepts for the sake of simplicity, such as:

- Connection pooling
- Swift `Codable` integration
- Query building

If you are looking for a MySQL client package to use in your project, take a look at these higher-level packages built on top of MySQLNIO:

- [`vapor/mysql-kit`](https://github.com/vapor/mysql-kit)

### Dependencies

This package has four dependencies:

- [`apple/swift-nio`](https://github.com/apple/swift-nio) for IO
- [`apple/swift-nio-ssl`](https://github.com/apple/swift-nio-ssl) for TLS
- [`apple/swift-log`](https://github.com/apple/swift-log) for logging
- [`apple/swift-crypto`](https://github.com/apple/swift-crypto) for cryptography

This package has no additional system dependencies.

## API Docs

Check out the [MySQLNIO API docs](https://api.vapor.codes/mysqlnio/documentation/mysqlnio/) for a detailed look at all of the classes, structs, protocols, and more.

## Getting Started

This section will provide a quick look at using MySQLNIO.

### Creating a Connection

The first step to making a query is creating a new `MySQLConnection`. The minimum requirements to create one are a `SocketAddress`, `EventLoop`, and credentials. 

```swift
import MySQLNIO

let eventLoop: any EventLoop = ...
let conn = try await MySQLConnection(
    to: .makeAddressResolvingHost("my.mysql.server", port: 3306),
    username: "test_username",
    database: "test_database",
    password: "test_password",
    on: eventLoop
).get()
```

There are a few ways to create a `SocketAddress`:

- `init(ipAddress: String, port: Int)`
- `init(unixDomainSocketPath: String)`
- `makeAddressResolvingHost(_ host: String, port: Int)`

There are also some additional arguments you can supply to `connect`. 

- `tlsConfiguration` An optional `TLSConfiguration` struct. This will be used if the MySQL server supports TLS. Pass `nil` to opt-out of TLS.
- `serverHostname` An optional `String` to use in conjunction with `tlsConfiguration` to specify the server's hostname. 

`connect` will return a `MySQLConnection`, or an error if it could not connect.

### Database Protocol

Interaction with a server revolves around the `MySQLDatabase` protocol. This protocol includes methods like `query(_:)` for executing SQL queries and reading the resulting rows. 

`MySQLConnection` is the default implementation of `MySQLDatabase` provided by this package. Assume the client here is the connection from the previous example.

```swift
import MySQLNIO

let db: any MySQLDatabase = ...
// now we can use client to do queries
```

### Simple Query

Simple (text) queries allow you to execute a SQL string on the connected MySQL server. These queries do not support binding parameters, so any values sent must be escaped manually.

These queries are most useful for schema or transactional queries, or simple selects. Note that values returned by simple queries will be transferred in the less efficient text format. 

`simpleQuery` has two overloads, one that returns an array of rows, and one that accepts a closure for handling each row as it is returned.

```swift
let rows = try await db.simpleQuery("SELECT @@version").get()
print(rows) // [["@@version": "8.x.x"]]

try await db.simpleQuery("SELECT @@version") { row in
    print(row) // ["@@version": "8.x.x"]
}.get()
```

### Parameterized Query

Parameterized (prepared statement) queries allow you to execute a SQL string on the connected MySQL server. These queries support passing bound parameters as a separate argument. Each parameter is represented in the SQL string using placeholders (`?`). 

These queries are most useful for selecting, inserting, and updating data. Data for these queries is transferred using the highly efficient binary format. 

Just like `simpleQuery`, `query` also offers two overloads. One that returns an array of rows, and one that accepts a closure for handling each row as it is returned.

```swift
let rows = try await db.query("SELECT * FROM planets WHERE name = ?", ["Earth"]).get()
print(rows) // [["id": 42, "name": "Earth"]]

try await db.query("SELECT * FROM planets WHERE name = ?", ["Earth"]) { row in
    print(row) // ["id": 42, "name": "Earth"]
}.get()
```

### Rows and Data

Both `simpleQuery` and `query` return the same `MySQLRow` type. Columns can be fetched from the row using the `column(_:table:)` method.

```swift
let row: any MySQLRow = ...
let version = row.column("name")
print(version) // MySQLData?
```

`MySQLRow` columns are stored as `MySQLData`. This struct contains the raw bytes returned by MySQL as well as some information for parsing them, such as:

- MySQL data type
- Wire format: binary or text
- Value as array of bytes

`MySQLData` has a variety of convenience methods for converting column data to usable Swift types.

```swift
let data: MySQLData = ...

print(data.string) // String?

print(data.int) // Int?
print(data.int8) // Int8?
print(data.int16) // Int16?
print(data.int32) // Int32?
print(data.int64) // Int64?

print(data.uint) // UInt?
print(data.uint8) // UInt8?
print(data.uint16) // UInt16?
print(data.uint32) // UInt32?
print(data.uint64) // UInt64?

print(data.bool) // Bool?

try print(data.json(as: Foo.self)) // Foo?

print(data.float) // Float?
print(data.double) // Double?

print(data.date) // Date?
print(data.uuid) // UUID?
print(data.decimal) // Decimal?

print(data.time) // MySQLTime?
```

`MySQLData` is also used for sending data _to_ the server via parameterized values. To create `MySQLData` from a Swift type, use the available intializer methods. 
