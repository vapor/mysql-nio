# `MySQLNIOCore`

The "new" implementation of MySQLNIO, a wire protocol driver for MySQL databases.

## Supported Versions

At the time of this writing, the following versions of the listed MySQL implementations are supported by this package:

- [MySQL](https://www.mysql.com/), versions 5.7+ and 8.0+
- [MariaDB](https://www.mariadb.com/), versions 10.5+ and 11.0+
- [Percona](https://www.percona.com/), versions 8.0+
- [Amazon Aurora MySQL](https://aws.amazon.com/rds/aurora/), versions 2.x and 3.x

Other MySQL server implementations will typically work as expected as long as they are compliant with the MySQL wire
protocol as documented in the [MySQL Internals manual](https://dev.mysql.com/doc/dev/mysql-server/latest/PAGE_PROTOCOL.html).

The following platforms are known to be supported:

- Ubuntu 20.04 ("Focal") and 22.04 ("Jammy")
- Amazon Linux 2
- macOS 10.15 or later
- iOS 13 or later

Additional platforms supported by Swift 5.7 or later should also work as expected. Support for tvOS and watchOS is, at
best, experimental.
