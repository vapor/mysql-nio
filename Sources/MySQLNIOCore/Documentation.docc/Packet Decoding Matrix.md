# Packet Decoding Matrix

Lists the various possible decodings for packets at each point in the connection lifetime.

##### ​

Each entry in this table gives a possible valid marker byte or range of valid marker bytes for the state (and, where applicable, substate) under which it appears. Any marker byte not listed for a given state is not valid in that state.

|||
|   -   | -                                            |
|**_ALL_**                                            ||
|`0xff` |`ERR_Packet`                                  |
|                                                     ||
|**`awaitingGreeting`**                               ||
|`0x0a` |`HandshakeV10`                                |
|                                                     ||
|**`awaitingAuthReply`**                              ||
|`0x00` |`OK_Packet`                                   |
|`0x01` |`AuthMoreData`                                |
|`0xfe` |`AuthSwitchRequest`                           |
|                                                     ||
|**`awaitingOK`**  /  **`preparingStatement`**        ||           
|`0x00` |`OK_Packet`                                   |
|                                                     ||
|**`awaitingOK(stats)`**                              ||    
|`<0x80`|`Statistics`                                  |
|                                                     ||
|**`runningPlainQuery`**                              ||  
|    ↪ **`waitingOnResult`**                          ||   
|`0x00` |`OK_Packet`                                   |
|`0xfb` |`LOCAL INFILE Request`                        |
|  `*`  |`Column count`                                |
|    ↪ **`awaitingMetadata`**                         ||   
|`0x03` |`ColumnDefinition41`                          |
|    ↪ **`readingRows`**                              ||
|  `*`  |`Text resultset row`                          |  
|`0xfe` |`OK(EOF)_Packet`                              |
|                                                     ||
|**`executingStatement`**  /  **`fetchingCursorData`**||
|    ↪ **`waitingOnResult`**                          ||
|`0x00` |`OK_Packet`                                   |
|`!0xfb`|`Column count`                                |
|    ↪ **`awaitingMetadata`**                         ||   
|`0x03` |`ColumnDefinition41`                          |
|    ↪ **`readingRows`**                              ||            
|`0x00` |`Binary resultset row`                        |
|`0xfe` |`OK(EOF)_Packet`                              |

## See Also

- [MySQL Client/Server Protocol documentation](https://dev.mysql.com/doc/dev/mysql-server/latest/PAGE_PROTOCOL.html)
- [MariaDB Client/Server Protocol documentation](https://mariadb.com/kb/en/clientserver-protocol/)
