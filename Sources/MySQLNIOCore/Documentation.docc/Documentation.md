# ``MySQLNIOCore``

@Metadata {
    @TitleHeading(Package)
}

🐬 Non-blocking, event-driven Swift client for MySQL built on SwiftNIO.

This is the _new_ implementation of MySQLNIO, a wire protocol driver for MySQL databases.

## Supported Versions

At the time of this writing, the following versions of the listed MySQL implementations are supported by this package:

Vendor|Versions
-|-
[MySQL](https://www.mysql.com/)|5.7.x, 8.0.x, 8.1.x
[MariaDB](https://www.mariadb.com/)|10.x after 10.2.0, 11.x
[Percona](https://www.percona.com/)|8.0.x
[Amazon Aurora MySQL](https://aws.amazon.com/rds/aurora/)|2.x, 3.x

Other MySQL server implementations will typically work as expected as long as they are compliant with the MySQL wire
protocol as documented in the [MySQL Internals Manual](https://dev.mysql.com/doc/dev/mysql-server/latest/PAGE_PROTOCOL.html)
and the [MariaDB Knowledge Base](https://mariadb.com/kb/en/clientserver-protocol/).

This package is compatible with all platforms supported by [SwiftNIO 2.x](https://github.com/apple/swift-nio/). It has
been specifically tested on the following platforms:

- Ubuntu 20.04 ("Focal") and 22.04 ("Jammy")
- Amazon Linux 2
- macOS 10.15 and later
- iOS 13 and later
