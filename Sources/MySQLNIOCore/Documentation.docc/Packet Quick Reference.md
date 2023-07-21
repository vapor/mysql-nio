# Packet Quick Reference

A quick reference for the various MySQL binary packet formats (the useful ones, anyway).
Framing (length and sequence ID) is not included.

### Details
After the first incoming `OK_Packet`, all outgoing packets except split packet continuations reset the current sequence ID. 

#### Format key
|||||
-|-|-|-
`<<`|server packet         |`>>`|client packet
`li`|length-encoded integer|`ls`|length-encoded string
`se`|EOF-terminated string |`0s`|NULL-terminated string
`iN`|N-byte integer        |`sN`|N-character string
`s?`|Variable-length string|`b?`|Variable-length binary
`be`|EOF-terminated binary |`()`|repeated group
`?(`|optional group        |`fs`|23-byte filler string
|||||

#### Packets
|||||
-|-|-|-
|**Common**||||
`<<`|`OK_Packet`     |`0x00`|`li li i2 i2 ls ls?`
`<<`|`OK_Packet(EOF)`|`0xfe`|`li li i2 i2 ls ls?`
`<<`|`ERR_Packet`    |`0xff`|`i2 s1 s5 se`
|**Handshake**||||
`<<`|`HandshakeV10`  |`0x0a`|`0s i4 s8 i1 i2 i1 i2 i2 i1 s10 s? 0s`
`>>`|`SSLRequest`    |      |`i4 i4 i1 fs`
`>>`|`ResponseV41`   |      |`i4 i4 i1 fs 0s ls 0s 0s li (ls ls) i1`
`<<`|`AuthSwitchReq` |`0xfe`|`0s be`
`>>`|`AuthSwitchResp`|      |`be`
`<<`|`AuthMoreData`  |`0x01`|`be`
`<<`|`AuthNextFactor`|`0x02`|`0s be`
|**Query common**||||
`<<`|`ColumnCount`   |      |`li ?(i1)`
`<<`|`ColumnDef41`   |      |`ls ls ls ls ls ls li i2 i4 i1 i2 i1`
|**Text query**||||
`>>`|`COM_QUERY`     |`0x03`|`li li ?(b? i1 (i2 ls) b?) se`
`<<`|`LOCAL INFILE`  |`0xfb`|`se`
`<<`|`TextRow`       |      |`(ls\|0xfb)`
|**Binary statement**||||
`>>`|`STMT_PREPARE`  |`0x16`|`0s`|
`<<`|`STMT_PREP_OK`  |`0x00`|`i4 i2 i2 i1 i2 i1`|
`>>`|`SEND_LONG_DATA`|`0x18`|`i4 i2 be`|
`>>`|`STMT_EXECUTE`  |`0x17`|`i4 i1 i4 li b? i1 (i2) ls b?`|
`>>`|`STMT_FETCH`    |`0x1c`|`i4 i4`|
`<<`|`BinaryRow`     |`0x00`|`b? (b?)`|
`>>`|`STMT_RESET`    |`0x1a`|`i4` |
`>>`|`STMT_CLOSE`    |`0x19`|`i4`|
**Utility**||||
`>>`|`COM_QUIT`      |`0x01`| |
`>>`|`COM_INIT_DB`   |`0x02`|`se`|
`>>`|`COM_STATISTICS`|`0x09`| |
`>>`|`COM_PING`      |`0x0e`| |
`>>`|`COM_RESET_CONN`|`0x1f`| |
|||||

## See Also

- [MySQL Client/Server Protocol documentation](https://dev.mysql.com/doc/dev/mysql-server/latest/PAGE_PROTOCOL.html)
- [MariaDB Client/Server Protocol documentation](https://mariadb.com/kb/en/clientserver-protocol/)
