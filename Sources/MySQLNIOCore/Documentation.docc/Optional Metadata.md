# Optional Metadata

## Overview

Both the text and binary resultset formats of MySQL's wire protocol include resultset metadata by default, which takes the form of a single `ColumnDefinition41` packet for each column in the result rows. While often useful, this metadata is equally often redundant, either because the client already knows what columns and types to expect or because the metadata is known to not have changed from a previous resultset (such as when executing a prepared statement multiple times). In cases of result sets with many columns but few rows, the unnecessary or repeated metadata can become a severe efficiency bottleneck.

MySQL and MariaDB have both devised solutions to for this problem. In both cases, the solution is to potentially skip sending metadata with a resultset. The immediate mechanism used by both implementations is largely identical - when the capability flag signaling support for metadata skipping is set, the initial column count packet sent for both text and binary resultsets contains an additional flag byte signaling whether or not any `ColumnDefinition41` packets will appear before the resultset rows.
    
Unfortunately, this is where the similarities end...

## MySQL Just Doesn't Even Care

In MySQL 8 (including both Percona Server and AWS's Aurora 3.x), the relevant capability flag is `CLIENT_OPTIONAL_RESULTSET_METADATA`, and a session-specific system variable named `resultset_metadata` is available. This variable is always set to `FULL` by default when a session is opened, and its value cannot be changed unless the capability flag is enabled for the session. If the client sets it to `NONE`, the server will unconditionally skip metadata for all subsequent text resultsets, prepared statement replies, and binary resultsets until and unless the value is reset to `FULL`.

An additional effect of the `CLIENT_OPTIONAL_RESULTSET_METADATA` capability is to extend the `COM_STMT_PREPARE_OK` response packet format to include the same flag as the column count packets of a resultset. In fact, the flag is included twice - once for the bound parameters metadata and again for the result set metadata. As currently implemented, the two flags will always be both set or both unset, but this does seemingly provide room for finer detail in the future. 

## MariaDB Knows Better Than You Do

By contrast, in MariaDB 10.6 or later (only), the capability flag is part of the MariaDB "extended" capability flags, and is named `MARIADB_CLIENT_CACHE_METADATA`. The client has no control over when metadata is provided; the server will send metadata regardless of the capability flag for all of these cases:

- Any text resultset
- The bound parameters and result column metadata returned from a `COM_STMT_PREPARE` command  
- When the column metadata to be returned from a `COM_STMT_EXECUTE` command has changed since the statement was prepared or last executed
- Any `CALL` query, including (if present) the resultset for the procedure's `OUT` parameters

Another way to say it is that the only time metadata will be skipped is when repeatedly executing the same prepared statement. Even then, it is skipped only if the values of the bound parameters for any particular execution do not result in a change of the column metadata (this can happen with, for example, a query such as `SELECT ?`, where the result type will be the same as the parameter type - this is obviously a contrived example, but such dependencies are common, though more subtle, in real queries).

## Do Either of These Help?

Both the "let the client decide" and "only cache when it's 'safe'" methods have their respective merits and drawbacks, of course.

MySQL's "all or none" approach, since it is under client control, allows clients which aren't interested in the metadata (most often because they already know the expected format of the data and don't need to be forgiving of variations) to skip the maximum amount of unnecessary data. And if a client does need somewhat finer-grained control, the `CLIENT_MULTI_STATEMENTS` capability allows tweaking the `resultset_metadata` setting more or less "inline" to other queries without incurring additional round-trip overhead, although this is obviously rather awkward at best. At the same time, clients must determine for themselves whether or not their "knowledge" of a given set of metadata may have become invalid, and asking for metadata if and when it _is_ needed - or vice versa - is not easy, nor always viable.

MariaDB's approach seeks to make sure clients always have the most up to date data, while skipping the metadata in the very limited situations where doing so is safe. The balance to this is that repeated executions of a single prepared statement are exactly the scenario where avoiding the metadata repetition will have the most significant impact. Still, this does require that any given use case lend itself to heavy reuse of the same query or queries; use cases which require interacting with many different tables (or really any variety of database object which cannot be specified in a prepared statement by a bound parameter, which is almost everything) are out of luck.

It is unfortunate that neither MySQL nor MariaDB support the other's mode of operation - clients could then choose whether "manual" or "automatic" control was more appropriate to their situation.

All in all, MariaDB's "caching" mode doesn't quite measure up to some of its other innovations - such as the UCA-14.0.0 text collations or the Ed25519 authentication plugin - in terms of desirable features for the other major MySQL implementations. But, unlike the "progress indicator" or the short-lived "multi-command" features, it also wouldn't be unwelcome.
