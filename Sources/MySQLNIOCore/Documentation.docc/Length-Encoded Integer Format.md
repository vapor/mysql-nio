# MySQL Length-Encoded Integers

A storage format for 64-bit integer values

MySQL defines a "length-encoded" storage format for integer values, capable of representing any 64-bit integer using between 1 and 9 bytes. While this format saves several bytes versus a static 8-byte storage format for values below 2¹⁶, it costs an extra byte for all larger values, and incurs all of the usual drawbacks of a variable-length encoding. Nonetheless, it is used extensively by MySQL's client/server wire protocol.

## Encoding Details

The format consists of one prefix byte, followed by zero, two, three, or eight bytes, depending on the prefix, which also determines the maximum value represented by the encoding. The following table gives the count of suffix bytes and the maximum represented (unsigned) value for the possible prefixes:

Prefix|Suffix|Maximum
:-:|:-:|-
`0x00`|`0`|`250`
`...`|||
`0xfa`|`0`|`250`
`0xfb`|-|invalid
`0xfc`|`2`|2¹⁶-1 (65535)
`0xfd`|`3`|2²⁴-1 (16,777,215)
`0xfe`|`8`|2⁶⁴-1
`0xff`|-|invalid

Suffix bytes, when present, are always in little-endian order.

## Signedness

The length-encoded integer format assumes that values are unsigned. Signed integers can be represented by sign-extension followed by bitwise conversion to the equivalent unsigned type; this may cause negative numbers to be stored using a large encoding. Doing this is not recommended; the wire protocol assumes that integers are always unsigned except in specific cases, none of which use the length-encoded format.

## Forbidden encodings  

There are two prefix bytes that are considered invalid for the length-encoded integer format:

- `0xff` (`255`)
  
  This value is used as the "marker" byte for the generic `ERR_Packet` format. Because such packets may be only 9 bytes in length, the use of `0xff` in length-encoded values would make it possible to mistake a packet whose format starts with a length-encoded integer (such as a column count packet received as a reply to a `COM_QUERY` or `COM_STMT_EXECUTE` command) for an `ERR_Packet`, or vice versa.

- `0xfb` (`251`)
  
  Similarly, this value is used as the "marker" byte for the "`LOCAL INFILE` request" packet format, which may appear as a reply to a `COM_QUERY` command.
  
  The aforementioned column count packet is also a possible reply to `COM_QUERY`, adding another potential ambiguity.
  
  Finally, worst of all, there are text resultset row packets (yet again a result of `COM_QUERY`). A text resultset row is a fixed-length list of values; a value is either a length-encoded string, or, an `0xfb` byte - signalling a `NULL` value. Some versions of the protocol documentation consider this usage part of the length-encoded integer format itself, but the `NULL` representation is valid _only_ in text resultset rows, making such an interpretation arguably misleading. (It is worth noting that the total size of such a packet must also be checked, in order to disambiguate a text resultset row starting with a 9-byte length-encoded integer from the an EOF packet.)

If either of these bytes appears where a length-encoded integer is expected, and it has already been verified that an `ERR_Packet` or `LOCAL INFILE` Request packet is not a possible alternative, the value can not be decoded. This is considered an unrecoverable protocol error, caused by either data corruption or an implementation bug.
