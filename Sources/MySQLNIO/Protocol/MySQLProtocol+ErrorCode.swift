extension MySQLProtocol {
    public struct ErrorCode: ExpressibleByIntegerLiteral, RawRepresentable, Equatable, CustomStringConvertible {
        /// `SERVER_INIT`
        public static let SERVER_INIT: ErrorCode = 1
        /// `ER_HASHCHK`
        public static let HASHCHK: ErrorCode = 1000
        /// `ER_NISAMCHK`
        public static let NISAMCHK: ErrorCode = 1001
        /// `ER_NO`
        public static let NO: ErrorCode = 1002
        /// `ER_YES`
        public static let YES: ErrorCode = 1003
        /// `ER_CANT_CREATE_FILE`
        public static let CANT_CREATE_FILE: ErrorCode = 1004
        /// `ER_CANT_CREATE_TABLE`
        public static let CANT_CREATE_TABLE: ErrorCode = 1005
        /// `ER_CANT_CREATE_DB`
        public static let CANT_CREATE_DB: ErrorCode = 1006
        /// `ER_DB_CREATE_EXISTS`
        public static let DB_CREATE_EXISTS: ErrorCode = 1007
        /// `ER_DB_DROP_EXISTS`
        public static let DB_DROP_EXISTS: ErrorCode = 1008
        /// `ER_DB_DROP_DELETE`
        public static let DB_DROP_DELETE: ErrorCode = 1009
        /// `ER_DB_DROP_RMDIR`
        public static let DB_DROP_RMDIR: ErrorCode = 1010
        /// `ER_CANT_DELETE_FILE`
        public static let CANT_DELETE_FILE: ErrorCode = 1011
        /// `ER_CANT_FIND_SYSTEM_REC`
        public static let CANT_FIND_SYSTEM_REC: ErrorCode = 1012
        /// `ER_CANT_GET_STAT`
        public static let CANT_GET_STAT: ErrorCode = 1013
        /// `ER_CANT_GET_WD`
        public static let CANT_GET_WD: ErrorCode = 1014
        /// `ER_CANT_LOCK`
        public static let CANT_LOCK: ErrorCode = 1015
        /// `ER_CANT_OPEN_FILE`
        public static let CANT_OPEN_FILE: ErrorCode = 1016
        /// `ER_FILE_NOT_FOUND`
        public static let FILE_NOT_FOUND: ErrorCode = 1017
        /// `ER_CANT_READ_DIR`
        public static let CANT_READ_DIR: ErrorCode = 1018
        /// `ER_CANT_SET_WD`
        public static let CANT_SET_WD: ErrorCode = 1019
        /// `ER_CHECKREAD`
        public static let CHECKREAD: ErrorCode = 1020
        /// `ER_DISK_FULL`
        public static let DISK_FULL: ErrorCode = 1021
        /// `ER_DUP_KEY`
        public static let DUP_KEY: ErrorCode = 1022
        /// `ER_ERROR_ON_CLOSE`
        public static let ERROR_ON_CLOSE: ErrorCode = 1023
        /// `ER_ERROR_ON_READ`
        public static let ERROR_ON_READ: ErrorCode = 1024
        /// `ER_ERROR_ON_RENAME`
        public static let ERROR_ON_RENAME: ErrorCode = 1025
        /// `ER_ERROR_ON_WRITE`
        public static let ERROR_ON_WRITE: ErrorCode = 1026
        /// `ER_FILE_USED`
        public static let FILE_USED: ErrorCode = 1027
        /// `ER_FILSORT_ABORT`
        public static let FILSORT_ABORT: ErrorCode = 1028
        /// `ER_FORM_NOT_FOUND`
        public static let FORM_NOT_FOUND: ErrorCode = 1029
        /// `ER_GET_ERRNO`
        public static let GET_ERRNO: ErrorCode = 1030
        /// `ER_ILLEGAL_HA`
        public static let ILLEGAL_HA: ErrorCode = 1031
        /// `ER_KEY_NOT_FOUND`
        public static let KEY_NOT_FOUND: ErrorCode = 1032
        /// `ER_NOT_FORM_FILE`
        public static let NOT_FORM_FILE: ErrorCode = 1033
        /// `ER_NOT_KEYFILE`
        public static let NOT_KEYFILE: ErrorCode = 1034
        /// `ER_OLD_KEYFILE`
        public static let OLD_KEYFILE: ErrorCode = 1035
        /// `ER_OPEN_AS_READONLY`
        public static let OPEN_AS_READONLY: ErrorCode = 1036
        /// `ER_OUTOFMEMORY`
        public static let OUTOFMEMORY: ErrorCode = 1037
        /// `ER_OUT_OF_SORTMEMORY`
        public static let OUT_OF_SORTMEMORY: ErrorCode = 1038
        /// `ER_UNEXPECTED_EOF`
        public static let UNEXPECTED_EOF: ErrorCode = 1039
        /// `ER_CON_COUNT_ERROR`
        public static let CON_COUNT_ERROR: ErrorCode = 1040
        /// `ER_OUT_OF_RESOURCES`
        public static let OUT_OF_RESOURCES: ErrorCode = 1041
        /// `ER_BAD_HOST_ERROR`
        public static let BAD_HOST_ERROR: ErrorCode = 1042
        /// `ER_HANDSHAKE_ERROR`
        public static let HANDSHAKE_ERROR: ErrorCode = 1043
        /// `ER_DBACCESS_DENIED_ERROR`
        public static let DBACCESS_DENIED_ERROR: ErrorCode = 1044
        /// `ER_ACCESS_DENIED_ERROR`
        public static let ACCESS_DENIED_ERROR: ErrorCode = 1045
        /// `ER_NO_DB_ERROR`
        public static let NO_DB_ERROR: ErrorCode = 1046
        /// `ER_UNKNOWN_COM_ERROR`
        public static let UNKNOWN_COM_ERROR: ErrorCode = 1047
        /// `ER_BAD_NULL_ERROR`
        public static let BAD_NULL_ERROR: ErrorCode = 1048
        /// `ER_BAD_DB_ERROR`
        public static let BAD_DB_ERROR: ErrorCode = 1049
        /// `ER_TABLE_EXISTS_ERROR`
        public static let TABLE_EXISTS_ERROR: ErrorCode = 1050
        /// `ER_BAD_TABLE_ERROR`
        public static let BAD_TABLE_ERROR: ErrorCode = 1051
        /// `ER_NON_UNIQ_ERROR`
        public static let NON_UNIQ_ERROR: ErrorCode = 1052
        /// `ER_SERVER_SHUTDOWN`
        public static let SERVER_SHUTDOWN: ErrorCode = 1053
        /// `ER_BAD_FIELD_ERROR`
        public static let BAD_FIELD_ERROR: ErrorCode = 1054
        /// `ER_WRONG_FIELD_WITH_GROUP`
        public static let WRONG_FIELD_WITH_GROUP: ErrorCode = 1055
        /// `ER_WRONG_GROUP_FIELD`
        public static let WRONG_GROUP_FIELD: ErrorCode = 1056
        /// `ER_WRONG_SUM_SELECT`
        public static let WRONG_SUM_SELECT: ErrorCode = 1057
        /// `ER_WRONG_VALUE_COUNT`
        public static let WRONG_VALUE_COUNT: ErrorCode = 1058
        /// `ER_TOO_LONG_IDENT`
        public static let TOO_LONG_IDENT: ErrorCode = 1059
        /// `ER_DUP_FIELDNAME`
        public static let DUP_FIELDNAME: ErrorCode = 1060
        /// `ER_DUP_KEYNAME`
        public static let DUP_KEYNAME: ErrorCode = 1061
        /// `ER_DUP_ENTRY`
        public static let DUP_ENTRY: ErrorCode = 1062
        /// `ER_WRONG_FIELD_SPEC`
        public static let WRONG_FIELD_SPEC: ErrorCode = 1063
        /// `ER_PARSE_ERROR`
        public static let PARSE_ERROR: ErrorCode = 1064
        /// `ER_EMPTY_QUERY`
        public static let EMPTY_QUERY: ErrorCode = 1065
        /// `ER_NONUNIQ_TABLE`
        public static let NONUNIQ_TABLE: ErrorCode = 1066
        /// `ER_INVALID_DEFAULT`
        public static let INVALID_DEFAULT: ErrorCode = 1067
        /// `ER_MULTIPLE_PRI_KEY`
        public static let MULTIPLE_PRI_KEY: ErrorCode = 1068
        /// `ER_TOO_MANY_KEYS`
        public static let TOO_MANY_KEYS: ErrorCode = 1069
        /// `ER_TOO_MANY_KEY_PARTS`
        public static let TOO_MANY_KEY_PARTS: ErrorCode = 1070
        /// `ER_TOO_LONG_KEY`
        public static let TOO_LONG_KEY: ErrorCode = 1071
        /// `ER_KEY_COLUMN_DOES_NOT_EXITS`
        public static let KEY_COLUMN_DOES_NOT_EXITS: ErrorCode = 1072
        /// `ER_BLOB_USED_AS_KEY`
        public static let BLOB_USED_AS_KEY: ErrorCode = 1073
        /// `ER_TOO_BIG_FIELDLENGTH`
        public static let TOO_BIG_FIELDLENGTH: ErrorCode = 1074
        /// `ER_WRONG_AUTO_KEY`
        public static let WRONG_AUTO_KEY: ErrorCode = 1075
        /// `ER_READY`
        public static let READY: ErrorCode = 1076
        /// `ER_NORMAL_SHUTDOWN`
        public static let NORMAL_SHUTDOWN: ErrorCode = 1077
        /// `ER_GOT_SIGNAL`
        public static let GOT_SIGNAL: ErrorCode = 1078
        /// `ER_SHUTDOWN_COMPLETE`
        public static let SHUTDOWN_COMPLETE: ErrorCode = 1079
        /// `ER_FORCING_CLOSE`
        public static let FORCING_CLOSE: ErrorCode = 1080
        /// `ER_IPSOCK_ERROR`
        public static let IPSOCK_ERROR: ErrorCode = 1081
        /// `ER_NO_SUCH_INDEX`
        public static let NO_SUCH_INDEX: ErrorCode = 1082
        /// `ER_WRONG_FIELD_TERMINATORS`
        public static let WRONG_FIELD_TERMINATORS: ErrorCode = 1083
        /// `ER_BLOBS_AND_NO_TERMINATED`
        public static let BLOBS_AND_NO_TERMINATED: ErrorCode = 1084
        /// `ER_TEXTFILE_NOT_READABLE`
        public static let TEXTFILE_NOT_READABLE: ErrorCode = 1085
        /// `ER_FILE_EXISTS_ERROR`
        public static let FILE_EXISTS_ERROR: ErrorCode = 1086
        /// `ER_LOAD_INFO`
        public static let LOAD_INFO: ErrorCode = 1087
        /// `ER_ALTER_INFO`
        public static let ALTER_INFO: ErrorCode = 1088
        /// `ER_WRONG_SUB_KEY`
        public static let WRONG_SUB_KEY: ErrorCode = 1089
        /// `ER_CANT_REMOVE_ALL_FIELDS`
        public static let CANT_REMOVE_ALL_FIELDS: ErrorCode = 1090
        /// `ER_CANT_DROP_FIELD_OR_KEY`
        public static let CANT_DROP_FIELD_OR_KEY: ErrorCode = 1091
        /// `ER_INSERT_INFO`
        public static let INSERT_INFO: ErrorCode = 1092
        /// `ER_UPDATE_TABLE_USED`
        public static let UPDATE_TABLE_USED: ErrorCode = 1093
        /// `ER_NO_SUCH_THREAD`
        public static let NO_SUCH_THREAD: ErrorCode = 1094
        /// `ER_KILL_DENIED_ERROR`
        public static let KILL_DENIED_ERROR: ErrorCode = 1095
        /// `ER_NO_TABLES_USED`
        public static let NO_TABLES_USED: ErrorCode = 1096
        /// `ER_TOO_BIG_SET`
        public static let TOO_BIG_SET: ErrorCode = 1097
        /// `ER_NO_UNIQUE_LOGFILE`
        public static let NO_UNIQUE_LOGFILE: ErrorCode = 1098
        /// `ER_TABLE_NOT_LOCKED_FOR_WRITE`
        public static let TABLE_NOT_LOCKED_FOR_WRITE: ErrorCode = 1099
        /// `ER_TABLE_NOT_LOCKED`
        public static let TABLE_NOT_LOCKED: ErrorCode = 1100
        /// `ER_BLOB_CANT_HAVE_DEFAULT`
        public static let BLOB_CANT_HAVE_DEFAULT: ErrorCode = 1101
        /// `ER_WRONG_DB_NAME`
        public static let WRONG_DB_NAME: ErrorCode = 1102
        /// `ER_WRONG_TABLE_NAME`
        public static let WRONG_TABLE_NAME: ErrorCode = 1103
        /// `ER_TOO_BIG_SELECT`
        public static let TOO_BIG_SELECT: ErrorCode = 1104
        /// `ER_UNKNOWN_ERROR`
        public static let UNKNOWN_ERROR: ErrorCode = 1105
        /// `ER_UNKNOWN_PROCEDURE`
        public static let UNKNOWN_PROCEDURE: ErrorCode = 1106
        /// `ER_WRONG_PARAMCOUNT_TO_PROCEDURE`
        public static let WRONG_PARAMCOUNT_TO_PROCEDURE: ErrorCode = 1107
        /// `ER_WRONG_PARAMETERS_TO_PROCEDURE`
        public static let WRONG_PARAMETERS_TO_PROCEDURE: ErrorCode = 1108
        /// `ER_UNKNOWN_TABLE`
        public static let UNKNOWN_TABLE: ErrorCode = 1109
        /// `ER_FIELD_SPECIFIED_TWICE`
        public static let FIELD_SPECIFIED_TWICE: ErrorCode = 1110
        /// `ER_INVALID_GROUP_FUNC_USE`
        public static let INVALID_GROUP_FUNC_USE: ErrorCode = 1111
        /// `ER_UNSUPPORTED_EXTENSION`
        public static let UNSUPPORTED_EXTENSION: ErrorCode = 1112
        /// `ER_TABLE_MUST_HAVE_COLUMNS`
        public static let TABLE_MUST_HAVE_COLUMNS: ErrorCode = 1113
        /// `ER_RECORD_FILE_FULL`
        public static let RECORD_FILE_FULL: ErrorCode = 1114
        /// `ER_UNKNOWN_CHARACTER_SET`
        public static let UNKNOWN_CHARACTER_SET: ErrorCode = 1115
        /// `ER_TOO_MANY_TABLES`
        public static let TOO_MANY_TABLES: ErrorCode = 1116
        /// `ER_TOO_MANY_FIELDS`
        public static let TOO_MANY_FIELDS: ErrorCode = 1117
        /// `ER_TOO_BIG_ROWSIZE`
        public static let TOO_BIG_ROWSIZE: ErrorCode = 1118
        /// `ER_STACK_OVERRUN`
        public static let STACK_OVERRUN: ErrorCode = 1119
        /// `ER_WRONG_OUTER_JOIN`
        public static let WRONG_OUTER_JOIN: ErrorCode = 1120
        /// `ER_NULL_COLUMN_IN_INDEX`
        public static let NULL_COLUMN_IN_INDEX: ErrorCode = 1121
        /// `ER_CANT_FIND_UDF`
        public static let CANT_FIND_UDF: ErrorCode = 1122
        /// `ER_CANT_INITIALIZE_UDF`
        public static let CANT_INITIALIZE_UDF: ErrorCode = 1123
        /// `ER_UDF_NO_PATHS`
        public static let UDF_NO_PATHS: ErrorCode = 1124
        /// `ER_UDF_EXISTS`
        public static let UDF_EXISTS: ErrorCode = 1125
        /// `ER_CANT_OPEN_LIBRARY`
        public static let CANT_OPEN_LIBRARY: ErrorCode = 1126
        /// `ER_CANT_FIND_DL_ENTRY`
        public static let CANT_FIND_DL_ENTRY: ErrorCode = 1127
        /// `ER_FUNCTION_NOT_DEFINED`
        public static let FUNCTION_NOT_DEFINED: ErrorCode = 1128
        /// `ER_HOST_IS_BLOCKED`
        public static let HOST_IS_BLOCKED: ErrorCode = 1129
        /// `ER_HOST_NOT_PRIVILEGED`
        public static let HOST_NOT_PRIVILEGED: ErrorCode = 1130
        /// `ER_PASSWORD_ANONYMOUS_USER`
        public static let PASSWORD_ANONYMOUS_USER: ErrorCode = 1131
        /// `ER_PASSWORD_NOT_ALLOWED`
        public static let PASSWORD_NOT_ALLOWED: ErrorCode = 1132
        /// `ER_PASSWORD_NO_MATCH`
        public static let PASSWORD_NO_MATCH: ErrorCode = 1133
        /// `ER_UPDATE_INFO`
        public static let UPDATE_INFO: ErrorCode = 1134
        /// `ER_CANT_CREATE_THREAD`
        public static let CANT_CREATE_THREAD: ErrorCode = 1135
        /// `ER_WRONG_VALUE_COUNT_ON_ROW`
        public static let WRONG_VALUE_COUNT_ON_ROW: ErrorCode = 1136
        /// `ER_CANT_REOPEN_TABLE`
        public static let CANT_REOPEN_TABLE: ErrorCode = 1137
        /// `ER_INVALID_USE_OF_NULL`
        public static let INVALID_USE_OF_NULL: ErrorCode = 1138
        /// `ER_REGEXP_ERROR`
        public static let REGEXP_ERROR: ErrorCode = 1139
        /// `ER_MIX_OF_GROUP_FUNC_AND_FIELDS`
        public static let MIX_OF_GROUP_FUNC_AND_FIELDS: ErrorCode = 1140
        /// `ER_NONEXISTING_GRANT`
        public static let NONEXISTING_GRANT: ErrorCode = 1141
        /// `ER_TABLEACCESS_DENIED_ERROR`
        public static let TABLEACCESS_DENIED_ERROR: ErrorCode = 1142
        /// `ER_COLUMNACCESS_DENIED_ERROR`
        public static let COLUMNACCESS_DENIED_ERROR: ErrorCode = 1143
        /// `ER_ILLEGAL_GRANT_FOR_TABLE`
        public static let ILLEGAL_GRANT_FOR_TABLE: ErrorCode = 1144
        /// `ER_GRANT_WRONG_HOST_OR_USER`
        public static let GRANT_WRONG_HOST_OR_USER: ErrorCode = 1145
        /// `ER_NO_SUCH_TABLE`
        public static let NO_SUCH_TABLE: ErrorCode = 1146
        /// `ER_NONEXISTING_TABLE_GRANT`
        public static let NONEXISTING_TABLE_GRANT: ErrorCode = 1147
        /// `ER_NOT_ALLOWED_COMMAND`
        public static let NOT_ALLOWED_COMMAND: ErrorCode = 1148
        /// `ER_SYNTAX_ERROR`
        public static let SYNTAX_ERROR: ErrorCode = 1149
        /// `ER_UNUSED1`
        public static let UNUSED1: ErrorCode  = 1150
        /// `ER_UNUSED2`
        public static let UNUSED2: ErrorCode  = 1151
        /// `ER_ABORTING_CONNECTION`
        public static let ABORTING_CONNECTION: ErrorCode = 1152
        /// `ER_NET_PACKET_TOO_LARGE`
        public static let NET_PACKET_TOO_LARGE: ErrorCode = 1153
        /// `ER_NET_READ_ERROR_FROM_PIPE`
        public static let NET_READ_ERROR_FROM_PIPE: ErrorCode = 1154
        /// `ER_NET_FCNTL_ERROR`
        public static let NET_FCNTL_ERROR: ErrorCode = 1155
        /// `ER_NET_PACKETS_OUT_OF_ORDER`
        public static let NET_PACKETS_OUT_OF_ORDER: ErrorCode = 1156
        /// `ER_NET_UNCOMPRESS_ERROR`
        public static let NET_UNCOMPRESS_ERROR: ErrorCode = 1157
        /// `ER_NET_READ_ERROR`
        public static let NET_READ_ERROR: ErrorCode = 1158
        /// `ER_NET_READ_INTERRUPTED`
        public static let NET_READ_INTERRUPTED: ErrorCode = 1159
        /// `ER_NET_ERROR_ON_WRITE`
        public static let NET_ERROR_ON_WRITE: ErrorCode = 1160
        /// `ER_NET_WRITE_INTERRUPTED`
        public static let NET_WRITE_INTERRUPTED: ErrorCode = 1161
        /// `ER_TOO_LONG_STRING`
        public static let TOO_LONG_STRING: ErrorCode = 1162
        /// `ER_TABLE_CANT_HANDLE_BLOB`
        public static let TABLE_CANT_HANDLE_BLOB: ErrorCode = 1163
        /// `ER_TABLE_CANT_HANDLE_AUTO_INCREMENT`
        public static let TABLE_CANT_HANDLE_AUTO_INCREMENT: ErrorCode = 1164
        /// `ER_UNUSED3`
        public static let UNUSED3: ErrorCode  = 1165
        /// `ER_WRONG_COLUMN_NAME`
        public static let WRONG_COLUMN_NAME: ErrorCode = 1166
        /// `ER_WRONG_KEY_COLUMN`
        public static let WRONG_KEY_COLUMN: ErrorCode = 1167
        /// `ER_WRONG_MRG_TABLE`
        public static let WRONG_MRG_TABLE: ErrorCode = 1168
        /// `ER_DUP_UNIQUE`
        public static let DUP_UNIQUE: ErrorCode = 1169
        /// `ER_BLOB_KEY_WITHOUT_LENGTH`
        public static let BLOB_KEY_WITHOUT_LENGTH: ErrorCode = 1170
        /// `ER_PRIMARY_CANT_HAVE_NULL`
        public static let PRIMARY_CANT_HAVE_NULL: ErrorCode = 1171
        /// `ER_TOO_MANY_ROWS`
        public static let TOO_MANY_ROWS: ErrorCode = 1172
        /// `ER_REQUIRES_PRIMARY_KEY`
        public static let REQUIRES_PRIMARY_KEY: ErrorCode = 1173
        /// `ER_NO_RAID_COMPILED`
        public static let NO_RAID_COMPILED: ErrorCode = 1174
        /// `ER_UPDATE_WITHOUT_KEY_IN_SAFE_MODE`
        public static let UPDATE_WITHOUT_KEY_IN_SAFE_MODE: ErrorCode = 1175
        /// `ER_KEY_DOES_NOT_EXITS`
        public static let KEY_DOES_NOT_EXITS: ErrorCode = 1176
        /// `ER_CHECK_NO_SUCH_TABLE`
        public static let CHECK_NO_SUCH_TABLE: ErrorCode = 1177
        /// `ER_CHECK_NOT_IMPLEMENTED`
        public static let CHECK_NOT_IMPLEMENTED: ErrorCode = 1178
        /// `ER_CANT_DO_THIS_DURING_AN_TRANSACTION`
        public static let CANT_DO_THIS_DURING_AN_TRANSACTION: ErrorCode = 1179
        /// `ER_ERROR_DURING_COMMIT`
        public static let ERROR_DURING_COMMIT: ErrorCode = 1180
        /// `ER_ERROR_DURING_ROLLBACK`
        public static let ERROR_DURING_ROLLBACK: ErrorCode = 1181
        /// `ER_ERROR_DURING_FLUSH_LOGS`
        public static let ERROR_DURING_FLUSH_LOGS: ErrorCode = 1182
        /// `ER_ERROR_DURING_CHECKPOINT`
        public static let ERROR_DURING_CHECKPOINT: ErrorCode = 1183
        /// `ER_NEW_ABORTING_CONNECTION`
        public static let NEW_ABORTING_CONNECTION: ErrorCode = 1184
        /// `ER_DUMP_NOT_IMPLEMENTED`
        public static let DUMP_NOT_IMPLEMENTED: ErrorCode = 1185
        /// `ER_FLUSH_MASTER_BINLOG_CLOSED`
        public static let FLUSH_MASTER_BINLOG_CLOSED: ErrorCode = 1186
        /// `ER_INDEX_REBUILD`
        public static let INDEX_REBUILD: ErrorCode = 1187
        /// `ER_MASTER`
        public static let MASTER: ErrorCode = 1188
        /// `ER_MASTER_NET_READ`
        public static let MASTER_NET_READ: ErrorCode = 1189
        /// `ER_MASTER_NET_WRITE`
        public static let MASTER_NET_WRITE: ErrorCode = 1190
        /// `ER_FT_MATCHING_KEY_NOT_FOUND`
        public static let FT_MATCHING_KEY_NOT_FOUND: ErrorCode = 1191
        /// `ER_LOCK_OR_ACTIVE_TRANSACTION`
        public static let LOCK_OR_ACTIVE_TRANSACTION: ErrorCode = 1192
        /// `ER_UNKNOWN_SYSTEM_VARIABLE`
        public static let UNKNOWN_SYSTEM_VARIABLE: ErrorCode = 1193
        /// `ER_CRASHED_ON_USAGE`
        public static let CRASHED_ON_USAGE: ErrorCode = 1194
        /// `ER_CRASHED_ON_REPAIR`
        public static let CRASHED_ON_REPAIR: ErrorCode = 1195
        /// `ER_WARNING_NOT_COMPLETE_ROLLBACK`
        public static let WARNING_NOT_COMPLETE_ROLLBACK: ErrorCode = 1196
        /// `ER_TRANS_CACHE_FULL`
        public static let TRANS_CACHE_FULL: ErrorCode = 1197
        /// `ER_SLAVE_MUST_STOP`
        public static let SLAVE_MUST_STOP: ErrorCode = 1198
        /// `ER_SLAVE_NOT_RUNNING`
        public static let SLAVE_NOT_RUNNING: ErrorCode = 1199
        /// `ER_BAD_SLAVE`
        public static let BAD_SLAVE: ErrorCode = 1200
        /// `ER_MASTER_INFO`
        public static let MASTER_INFO: ErrorCode = 1201
        /// `ER_SLAVE_THREAD`
        public static let SLAVE_THREAD: ErrorCode = 1202
        /// `ER_TOO_MANY_USER_CONNECTIONS`
        public static let TOO_MANY_USER_CONNECTIONS: ErrorCode = 1203
        /// `ER_SET_CONSTANTS_ONLY`
        public static let SET_CONSTANTS_ONLY: ErrorCode = 1204
        /// `ER_LOCK_WAIT_TIMEOUT`
        public static let LOCK_WAIT_TIMEOUT: ErrorCode = 1205
        /// `ER_LOCK_TABLE_FULL`
        public static let LOCK_TABLE_FULL: ErrorCode = 1206
        /// `ER_READ_ONLY_TRANSACTION`
        public static let READ_ONLY_TRANSACTION: ErrorCode = 1207
        /// `ER_DROP_DB_WITH_READ_LOCK`
        public static let DROP_DB_WITH_READ_LOCK: ErrorCode = 1208
        /// `ER_CREATE_DB_WITH_READ_LOCK`
        public static let CREATE_DB_WITH_READ_LOCK: ErrorCode = 1209
        /// `ER_WRONG_ARGUMENTS`
        public static let WRONG_ARGUMENTS: ErrorCode = 1210
        /// `ER_NO_PERMISSION_TO_CREATE_USER`
        public static let NO_PERMISSION_TO_CREATE_USER: ErrorCode = 1211
        /// `ER_UNION_TABLES_IN_DIFFERENT_DIR`
        public static let UNION_TABLES_IN_DIFFERENT_DIR: ErrorCode = 1212
        /// `ER_LOCK_DEADLOCK`
        public static let LOCK_DEADLOCK: ErrorCode = 1213
        /// `ER_TABLE_CANT_HANDLE_FT`
        public static let TABLE_CANT_HANDLE_FT: ErrorCode = 1214
        /// `ER_CANNOT_ADD_FOREIGN`
        public static let CANNOT_ADD_FOREIGN: ErrorCode = 1215
        /// `ER_NO_REFERENCED_ROW`
        public static let NO_REFERENCED_ROW: ErrorCode = 1216
        /// `ER_ROW_IS_REFERENCED`
        public static let ROW_IS_REFERENCED: ErrorCode = 1217
        /// `ER_CONNECT_TO_MASTER`
        public static let CONNECT_TO_MASTER: ErrorCode = 1218
        /// `ER_QUERY_ON_MASTER`
        public static let QUERY_ON_MASTER: ErrorCode = 1219
        /// `ER_ERROR_WHEN_EXECUTING_COMMAND`
        public static let ERROR_WHEN_EXECUTING_COMMAND: ErrorCode = 1220
        /// `ER_WRONG_USAGE`
        public static let WRONG_USAGE: ErrorCode = 1221
        /// `ER_WRONG_NUMBER_OF_COLUMNS_IN_SELECT`
        public static let WRONG_NUMBER_OF_COLUMNS_IN_SELECT: ErrorCode = 1222
        /// `ER_CANT_UPDATE_WITH_READLOCK`
        public static let CANT_UPDATE_WITH_READLOCK: ErrorCode = 1223
        /// `ER_MIXING_NOT_ALLOWED`
        public static let MIXING_NOT_ALLOWED: ErrorCode = 1224
        /// `ER_DUP_ARGUMENT`
        public static let DUP_ARGUMENT: ErrorCode = 1225
        /// `ER_USER_LIMIT_REACHED`
        public static let USER_LIMIT_REACHED: ErrorCode = 1226
        /// `ER_SPECIFIC_ACCESS_DENIED_ERROR`
        public static let SPECIFIC_ACCESS_DENIED_ERROR: ErrorCode = 1227
        /// `ER_LOCAL_VARIABLE`
        public static let LOCAL_VARIABLE: ErrorCode = 1228
        /// `ER_GLOBAL_VARIABLE`
        public static let GLOBAL_VARIABLE: ErrorCode = 1229
        /// `ER_NO_DEFAULT`
        public static let NO_DEFAULT: ErrorCode = 1230
        /// `ER_WRONG_VALUE_FOR_VAR`
        public static let WRONG_VALUE_FOR_VAR: ErrorCode = 1231
        /// `ER_WRONG_TYPE_FOR_VAR`
        public static let WRONG_TYPE_FOR_VAR: ErrorCode = 1232
        /// `ER_VAR_CANT_BE_READ`
        public static let VAR_CANT_BE_READ: ErrorCode = 1233
        /// `ER_CANT_USE_OPTION_HERE`
        public static let CANT_USE_OPTION_HERE: ErrorCode = 1234
        /// `ER_NOT_SUPPORTED_YET`
        public static let NOT_SUPPORTED_YET: ErrorCode = 1235
        /// `ER_MASTER_FATAL_ERROR_READING_BINLOG`
        public static let MASTER_FATAL_ERROR_READING_BINLOG: ErrorCode = 1236
        /// `ER_SLAVE_IGNORED_TABLE`
        public static let SLAVE_IGNORED_TABLE: ErrorCode = 1237
        /// `ER_INCORRECT_GLOBAL_LOCAL_VAR`
        public static let INCORRECT_GLOBAL_LOCAL_VAR: ErrorCode = 1238
        /// `ER_WRONG_FK_DEF`
        public static let WRONG_FK_DEF: ErrorCode = 1239
        /// `ER_KEY_REF_DO_NOT_MATCH_TABLE_REF`
        public static let KEY_REF_DO_NOT_MATCH_TABLE_REF: ErrorCode = 1240
        /// `ER_OPERAND_COLUMNS`
        public static let OPERAND_COLUMNS: ErrorCode = 1241
        /// `ER_SUBQUERY_NO_1_ROW`
        public static let SUBQUERY_NO_1_ROW: ErrorCode = 1242
        /// `ER_UNKNOWN_STMT_HANDLER`
        public static let UNKNOWN_STMT_HANDLER: ErrorCode = 1243
        /// `ER_CORRUPT_HELP_DB`
        public static let CORRUPT_HELP_DB: ErrorCode = 1244
        /// `ER_CYCLIC_REFERENCE`
        public static let CYCLIC_REFERENCE: ErrorCode = 1245
        /// `ER_AUTO_CONVERT`
        public static let AUTO_CONVERT: ErrorCode = 1246
        /// `ER_ILLEGAL_REFERENCE`
        public static let ILLEGAL_REFERENCE: ErrorCode = 1247
        /// `ER_DERIVED_MUST_HAVE_ALIAS`
        public static let DERIVED_MUST_HAVE_ALIAS: ErrorCode = 1248
        /// `ER_SELECT_REDUCED`
        public static let SELECT_REDUCED: ErrorCode = 1249
        /// `ER_TABLENAME_NOT_ALLOWED_HERE`
        public static let TABLENAME_NOT_ALLOWED_HERE: ErrorCode = 1250
        /// `ER_NOT_SUPPORTED_AUTH_MODE`
        public static let NOT_SUPPORTED_AUTH_MODE: ErrorCode = 1251
        /// `ER_SPATIAL_CANT_HAVE_NULL`
        public static let SPATIAL_CANT_HAVE_NULL: ErrorCode = 1252
        /// `ER_COLLATION_CHARSET_MISMATCH`
        public static let COLLATION_CHARSET_MISMATCH: ErrorCode = 1253
        /// `ER_SLAVE_WAS_RUNNING`
        public static let SLAVE_WAS_RUNNING: ErrorCode = 1254
        /// `ER_SLAVE_WAS_NOT_RUNNING`
        public static let SLAVE_WAS_NOT_RUNNING: ErrorCode = 1255
        /// `ER_TOO_BIG_FOR_UNCOMPRESS`
        public static let TOO_BIG_FOR_UNCOMPRESS: ErrorCode = 1256
        /// `ER_ZLIB_Z_MEM_ERROR`
        public static let ZLIB_Z_MEM_ERROR: ErrorCode = 1257
        /// `ER_ZLIB_Z_BUF_ERROR`
        public static let ZLIB_Z_BUF_ERROR: ErrorCode = 1258
        /// `ER_ZLIB_Z_DATA_ERROR`
        public static let ZLIB_Z_DATA_ERROR: ErrorCode = 1259
        /// `ER_CUT_VALUE_GROUP_CONCAT`
        public static let CUT_VALUE_GROUP_CONCAT: ErrorCode = 1260
        /// `ER_WARN_TOO_FEW_RECORDS`
        public static let WARN_TOO_FEW_RECORDS: ErrorCode = 1261
        /// `ER_WARN_TOO_MANY_RECORDS`
        public static let WARN_TOO_MANY_RECORDS: ErrorCode = 1262
        /// `ER_WARN_NULL_TO_NOTNULL`
        public static let WARN_NULL_TO_NOTNULL: ErrorCode = 1263
        /// `ER_WARN_DATA_OUT_OF_RANGE`
        public static let WARN_DATA_OUT_OF_RANGE: ErrorCode = 1264
        /// `WARN_DATA_TRUNCATED`
        public static let WARN_DATA_TRUNCATED: ErrorCode = 1265
        /// `ER_WARN_USING_OTHER_HANDLER`
        public static let WARN_USING_OTHER_HANDLER: ErrorCode = 1266
        /// `ER_CANT_AGGREGATE_2COLLATIONS`
        public static let CANT_AGGREGATE_2COLLATIONS: ErrorCode = 1267
        /// `ER_DROP_USER`
        public static let DROP_USER: ErrorCode = 1268
        /// `ER_REVOKE_GRANTS`
        public static let REVOKE_GRANTS: ErrorCode = 1269
        /// `ER_CANT_AGGREGATE_3COLLATIONS`
        public static let CANT_AGGREGATE_3COLLATIONS: ErrorCode = 1270
        /// `ER_CANT_AGGREGATE_NCOLLATIONS`
        public static let CANT_AGGREGATE_NCOLLATIONS: ErrorCode = 1271
        /// `ER_VARIABLE_IS_NOT_STRUCT`
        public static let VARIABLE_IS_NOT_STRUCT: ErrorCode = 1272
        /// `ER_UNKNOWN_COLLATION`
        public static let UNKNOWN_COLLATION: ErrorCode = 1273
        /// `ER_SLAVE_IGNORED_SSL_PARAMS`
        public static let SLAVE_IGNORED_SSL_PARAMS: ErrorCode = 1274
        /// `ER_SERVER_IS_IN_SECURE_AUTH_MODE`
        public static let SERVER_IS_IN_SECURE_AUTH_MODE: ErrorCode = 1275
        /// `ER_WARN_FIELD_RESOLVED`
        public static let WARN_FIELD_RESOLVED: ErrorCode = 1276
        /// `ER_BAD_SLAVE_UNTIL_COND`
        public static let BAD_SLAVE_UNTIL_COND: ErrorCode = 1277
        /// `ER_MISSING_SKIP_SLAVE`
        public static let MISSING_SKIP_SLAVE: ErrorCode = 1278
        /// `ER_UNTIL_COND_IGNORED`
        public static let UNTIL_COND_IGNORED: ErrorCode = 1279
        /// `ER_WRONG_NAME_FOR_INDEX`
        public static let WRONG_NAME_FOR_INDEX: ErrorCode = 1280
        /// `ER_WRONG_NAME_FOR_CATALOG`
        public static let WRONG_NAME_FOR_CATALOG: ErrorCode = 1281
        /// `ER_WARN_QC_RESIZE`
        public static let WARN_QC_RESIZE: ErrorCode = 1282
        /// `ER_BAD_FT_COLUMN`
        public static let BAD_FT_COLUMN: ErrorCode = 1283
        /// `ER_UNKNOWN_KEY_CACHE`
        public static let UNKNOWN_KEY_CACHE: ErrorCode = 1284
        /// `ER_WARN_HOSTNAME_WONT_WORK`
        public static let WARN_HOSTNAME_WONT_WORK: ErrorCode = 1285
        /// `ER_UNKNOWN_STORAGE_ENGINE`
        public static let UNKNOWN_STORAGE_ENGINE: ErrorCode = 1286
        /// `ER_WARN_DEPRECATED_SYNTAX`
        public static let WARN_DEPRECATED_SYNTAX: ErrorCode = 1287
        /// `ER_NON_UPDATABLE_TABLE`
        public static let NON_UPDATABLE_TABLE: ErrorCode = 1288
        /// `ER_FEATURE_DISABLED`
        public static let FEATURE_DISABLED: ErrorCode = 1289
        /// `ER_OPTION_PREVENTS_STATEMENT`
        public static let OPTION_PREVENTS_STATEMENT: ErrorCode = 1290
        /// `ER_DUPLICATED_VALUE_IN_TYPE`
        public static let DUPLICATED_VALUE_IN_TYPE: ErrorCode = 1291
        /// `ER_TRUNCATED_WRONG_VALUE`
        public static let TRUNCATED_WRONG_VALUE: ErrorCode = 1292
        /// `ER_TOO_MUCH_AUTO_TIMESTAMP_COLS`
        public static let TOO_MUCH_AUTO_TIMESTAMP_COLS: ErrorCode = 1293
        /// `ER_INVALID_ON_UPDATE`
        public static let INVALID_ON_UPDATE: ErrorCode = 1294
        /// `ER_UNSUPPORTED_PS`
        public static let UNSUPPORTED_PS: ErrorCode = 1295
        /// `ER_GET_ERRMSG`
        public static let GET_ERRMSG: ErrorCode = 1296
        /// `ER_GET_TEMPORARY_ERRMSG`
        public static let GET_TEMPORARY_ERRMSG: ErrorCode = 1297
        /// `ER_UNKNOWN_TIME_ZONE`
        public static let UNKNOWN_TIME_ZONE: ErrorCode = 1298
        /// `ER_WARN_INVALID_TIMESTAMP`
        public static let WARN_INVALID_TIMESTAMP: ErrorCode = 1299
        /// `ER_INVALID_CHARACTER_STRING`
        public static let INVALID_CHARACTER_STRING: ErrorCode = 1300
        /// `ER_WARN_ALLOWED_PACKET_OVERFLOWED`
        public static let WARN_ALLOWED_PACKET_OVERFLOWED: ErrorCode = 1301
        /// `ER_CONFLICTING_DECLARATIONS`
        public static let CONFLICTING_DECLARATIONS: ErrorCode = 1302
        /// `ER_SP_NO_RECURSIVE_CREATE`
        public static let SP_NO_RECURSIVE_CREATE: ErrorCode = 1303
        /// `ER_SP_ALREADY_EXISTS`
        public static let SP_ALREADY_EXISTS: ErrorCode = 1304
        /// `ER_SP_DOES_NOT_EXIST`
        public static let SP_DOES_NOT_EXIST: ErrorCode = 1305
        /// `ER_SP_DROP_FAILED`
        public static let SP_DROP_FAILED: ErrorCode = 1306
        /// `ER_SP_STORE_FAILED`
        public static let SP_STORE_FAILED: ErrorCode = 1307
        /// `ER_SP_LILABEL_MISMATCH`
        public static let SP_LILABEL_MISMATCH: ErrorCode = 1308
        /// `ER_SP_LABEL_REDEFINE`
        public static let SP_LABEL_REDEFINE: ErrorCode = 1309
        /// `ER_SP_LABEL_MISMATCH`
        public static let SP_LABEL_MISMATCH: ErrorCode = 1310
        /// `ER_SP_UNINIT_VAR`
        public static let SP_UNINIT_VAR: ErrorCode = 1311
        /// `ER_SP_BADSELECT`
        public static let SP_BADSELECT: ErrorCode = 1312
        /// `ER_SP_BADRETURN`
        public static let SP_BADRETURN: ErrorCode = 1313
        /// `ER_SP_BADSTATEMENT`
        public static let SP_BADSTATEMENT: ErrorCode = 1314
        /// `ER_UPDATE_LOG_DEPRECATED_IGNORED`
        public static let UPDATE_LOG_DEPRECATED_IGNORED: ErrorCode = 1315
        /// `ER_UPDATE_LOG_DEPRECATED_TRANSLATED`
        public static let UPDATE_LOG_DEPRECATED_TRANSLATED: ErrorCode = 1316
        /// `ER_QUERY_INTERRUPTED`
        public static let QUERY_INTERRUPTED: ErrorCode = 1317
        /// `ER_SP_WRONG_NO_OF_ARGS`
        public static let SP_WRONG_NO_OF_ARGS: ErrorCode = 1318
        /// `ER_SP_COND_MISMATCH`
        public static let SP_COND_MISMATCH: ErrorCode = 1319
        /// `ER_SP_NORETURN`
        public static let SP_NORETURN: ErrorCode = 1320
        /// `ER_SP_NORETURNEND`
        public static let SP_NORETURNEND: ErrorCode = 1321
        /// `ER_SP_BAD_CURSOR_QUERY`
        public static let SP_BAD_CURSOR_QUERY: ErrorCode = 1322
        /// `ER_SP_BAD_CURSOR_SELECT`
        public static let SP_BAD_CURSOR_SELECT: ErrorCode = 1323
        /// `ER_SP_CURSOR_MISMATCH`
        public static let SP_CURSOR_MISMATCH: ErrorCode = 1324
        /// `ER_SP_CURSOR_ALREADY_OPEN`
        public static let SP_CURSOR_ALREADY_OPEN: ErrorCode = 1325
        /// `ER_SP_CURSOR_NOT_OPEN`
        public static let SP_CURSOR_NOT_OPEN: ErrorCode = 1326
        /// `ER_SP_UNDECLARED_VAR`
        public static let SP_UNDECLARED_VAR: ErrorCode = 1327
        /// `ER_SP_WRONG_NO_OF_FETCH_ARGS`
        public static let SP_WRONG_NO_OF_FETCH_ARGS: ErrorCode = 1328
        /// `ER_SP_FETCH_NO_DATA`
        public static let SP_FETCH_NO_DATA: ErrorCode = 1329
        /// `ER_SP_DUP_PARAM`
        public static let SP_DUP_PARAM: ErrorCode = 1330
        /// `ER_SP_DUP_VAR`
        public static let SP_DUP_VAR: ErrorCode = 1331
        /// `ER_SP_DUP_COND`
        public static let SP_DUP_COND: ErrorCode = 1332
        /// `ER_SP_DUP_CURS`
        public static let SP_DUP_CURS: ErrorCode = 1333
        /// `ER_SP_CANT_ALTER`
        public static let SP_CANT_ALTER: ErrorCode = 1334
        /// `ER_SP_SUBSELECT_NYI`
        public static let SP_SUBSELECT_NYI: ErrorCode = 1335
        /// `ER_STMT_NOT_ALLOWED_IN_SF_OR_TRG`
        public static let STMT_NOT_ALLOWED_IN_SF_OR_TRG: ErrorCode = 1336
        /// `ER_SP_VARCOND_AFTER_CURSHNDLR`
        public static let SP_VARCOND_AFTER_CURSHNDLR: ErrorCode = 1337
        /// `ER_SP_CURSOR_AFTER_HANDLER`
        public static let SP_CURSOR_AFTER_HANDLER: ErrorCode = 1338
        /// NOT_FOUND
        public static let _FOUND: ErrorCode = 1339
        /// `ER_FPARSER_TOO_BIG_FILE`
        public static let FPARSER_TOO_BIG_FILE: ErrorCode = 1340
        /// `ER_FPARSER_BAD_HEADER`
        public static let FPARSER_BAD_HEADER: ErrorCode = 1341
        /// `ER_FPARSER_EOF_IN_COMMENT`
        public static let FPARSER_EOF_IN_COMMENT: ErrorCode = 1342
        /// `ER_FPARSER_ERROR_IN_PARAMETER`
        public static let FPARSER_ERROR_IN_PARAMETER: ErrorCode = 1343
        /// `ER_FPARSER_EOF_IN_UNKNOWN_PARAMETER`
        public static let FPARSER_EOF_IN_UNKNOWN_PARAMETER: ErrorCode = 1344
        /// `ER_VIEW_NO_EXPLAIN`
        public static let VIEW_NO_EXPLAIN: ErrorCode = 1345
        /// `ER_FRM_UNKNOWN_TYPE`
        public static let FRM_UNKNOWN_TYPE: ErrorCode = 1346
        /// `ER_WRONG_OBJECT`
        public static let WRONG_OBJECT: ErrorCode = 1347
        /// `ER_NONUPDATEABLE_COLUMN`
        public static let NONUPDATEABLE_COLUMN: ErrorCode = 1348
        /// `ER_VIEW_SELECT_DERIVED_UNUSED`
        public static let VIEW_SELECT_DERIVED_UNUSED: ErrorCode = 1349
        /// `ER_VIEW_SELECT_CLAUSE`
        public static let VIEW_SELECT_CLAUSE: ErrorCode = 1350
        /// `ER_VIEW_SELECT_VARIABLE`
        public static let VIEW_SELECT_VARIABLE: ErrorCode = 1351
        /// `ER_VIEW_SELECT_TMPTABLE`
        public static let VIEW_SELECT_TMPTABLE: ErrorCode = 1352
        /// `ER_VIEW_WRONG_LIST`
        public static let VIEW_WRONG_LIST: ErrorCode = 1353
        /// `ER_WARN_VIEW_MERGE`
        public static let WARN_VIEW_MERGE: ErrorCode = 1354
        /// `ER_WARN_VIEW_WITHOUT_KEY`
        public static let WARN_VIEW_WITHOUT_KEY: ErrorCode = 1355
        /// `ER_VIEW_INVALID`
        public static let VIEW_INVALID: ErrorCode = 1356
        /// `ER_SP_NO_DROP_SP`
        public static let SP_NO_DROP_SP: ErrorCode = 1357
        /// `ER_SP_GOTO_IN_HNDLR`
        public static let SP_GOTO_IN_HNDLR: ErrorCode = 1358
        /// `ER_TRG_ALREADY_EXISTS`
        public static let TRG_ALREADY_EXISTS: ErrorCode = 1359
        /// `ER_TRG_DOES_NOT_EXIST`
        public static let TRG_DOES_NOT_EXIST: ErrorCode = 1360
        /// `ER_TRG_ON_VIEW_OR_TEMP_TABLE`
        public static let TRG_ON_VIEW_OR_TEMP_TABLE: ErrorCode = 1361
        /// `ER_TRG_CANT_CHANGE_ROW`
        public static let TRG_CANT_CHANGE_ROW: ErrorCode = 1362
        /// `ER_TRG_NO_SUCH_ROW_IN_TRG`
        public static let TRG_NO_SUCH_ROW_IN_TRG: ErrorCode = 1363
        /// `ER_NO_DEFAULT_FOR_FIELD`
        public static let NO_DEFAULT_FOR_FIELD: ErrorCode = 1364
        /// `ER_DIVISION_BY_ZERO`
        public static let DIVISION_BY_ZERO: ErrorCode = 1365
        /// `ER_TRUNCATED_WRONG_VALUE_FOR_FIELD`
        public static let TRUNCATED_WRONG_VALUE_FOR_FIELD: ErrorCode = 1366
        /// `ER_ILLEGAL_VALUE_FOR_TYPE`
        public static let ILLEGAL_VALUE_FOR_TYPE: ErrorCode = 1367
        /// `ER_VIEW_NONUPD_CHECK`
        public static let VIEW_NONUPD_CHECK: ErrorCode = 1368
        /// `ER_VIEW_CHECK_FAILED`
        public static let VIEW_CHECK_FAILED: ErrorCode = 1369
        /// `ER_PROCACCESS_DENIED_ERROR`
        public static let PROCACCESS_DENIED_ERROR: ErrorCode = 1370
        /// `ER_RELAY_LOG_FAIL`
        public static let RELAY_LOG_FAIL: ErrorCode = 1371
        /// `ER_PASSWD_LENGTH`
        public static let PASSWD_LENGTH: ErrorCode = 1372
        /// `ER_UNKNOWN_TARGET_BINLOG`
        public static let UNKNOWN_TARGET_BINLOG: ErrorCode = 1373
        /// `ER_IO_ERR_LOG_INDEX_READ`
        public static let IO_ERR_LOG_INDEX_READ: ErrorCode = 1374
        /// `ER_BINLOG_PURGE_PROHIBITED`
        public static let BINLOG_PURGE_PROHIBITED: ErrorCode = 1375
        /// `ER_FSEEK_FAIL`
        public static let FSEEK_FAIL: ErrorCode = 1376
        /// `ER_BINLOG_PURGE_FATAL_ERR`
        public static let BINLOG_PURGE_FATAL_ERR: ErrorCode = 1377
        /// `ER_LOG_IN_USE`
        public static let LOG_IN_USE: ErrorCode = 1378
        /// `ER_LOG_PURGE_UNKNOWN_ERR`
        public static let LOG_PURGE_UNKNOWN_ERR: ErrorCode = 1379
        /// `ER_RELAY_LOG_INIT`
        public static let RELAY_LOG_INIT: ErrorCode = 1380
        /// `ER_NO_BINARY_LOGGING`
        public static let NO_BINARY_LOGGING: ErrorCode = 1381
        /// `ER_RESERVED_SYNTAX`
        public static let RESERVED_SYNTAX: ErrorCode = 1382
        /// `ER_WSAS_FAILED`
        public static let WSAS_FAILED: ErrorCode = 1383
        /// `ER_DIFF_GROUPS_PROC`
        public static let DIFF_GROUPS_PROC: ErrorCode = 1384
        /// `ER_NO_GROUP_FOR_PROC`
        public static let NO_GROUP_FOR_PROC: ErrorCode = 1385
        /// `ER_ORDER_WITH_PROC`
        public static let ORDER_WITH_PROC: ErrorCode = 1386
        /// `ER_LOGGING_PROHIBIT_CHANGING_OF`
        public static let LOGGING_PROHIBIT_CHANGING_OF: ErrorCode = 1387
        /// `ER_NO_FILE_MAPPING`
        public static let NO_FILE_MAPPING: ErrorCode = 1388
        /// `ER_WRONG_MAGIC`
        public static let WRONG_MAGIC: ErrorCode = 1389
        /// `ER_PS_MANY_PARAM`
        public static let PS_MANY_PARAM: ErrorCode = 1390
        /// `ER_KEY_PART_0`
        public static let KEY_PART_0: ErrorCode  = 1391
        /// `ER_VIEW_CHECKSUM`
        public static let VIEW_CHECKSUM: ErrorCode = 1392
        /// `ER_VIEW_MULTIUPDATE`
        public static let VIEW_MULTIUPDATE: ErrorCode = 1393
        /// `ER_VIEW_NO_INSERT_FIELD_LIST`
        public static let VIEW_NO_INSERT_FIELD_LIST: ErrorCode = 1394
        /// `ER_VIEW_DELETE_MERGE_VIEW`
        public static let VIEW_DELETE_MERGE_VIEW: ErrorCode = 1395
        /// `ER_CANNOT_USER`
        public static let CANNOT_USER: ErrorCode = 1396
        /// `ER_XAER_NOTA`
        public static let XAER_NOTA: ErrorCode = 1397
        /// `ER_XAER_INVAL`
        public static let XAER_INVAL: ErrorCode = 1398
        /// `ER_XAER_RMFAIL`
        public static let XAER_RMFAIL: ErrorCode = 1399
        /// `ER_XAER_OUTSIDE`
        public static let XAER_OUTSIDE: ErrorCode = 1400
        /// `ER_XAER_RMERR`
        public static let XAER_RMERR: ErrorCode = 1401
        /// `ER_XA_RBROLLBACK`
        public static let XA_RBROLLBACK: ErrorCode = 1402
        /// `ER_NONEXISTING_PROC_GRANT`
        public static let NONEXISTING_PROC_GRANT: ErrorCode = 1403
        /// `ER_PROC_AUTO_GRANT_FAIL`
        public static let PROC_AUTO_GRANT_FAIL: ErrorCode = 1404
        /// `ER_PROC_AUTO_REVOKE_FAIL`
        public static let PROC_AUTO_REVOKE_FAIL: ErrorCode = 1405
        /// `ER_DATA_TOO_LONG`
        public static let DATA_TOO_LONG: ErrorCode = 1406
        /// `ER_SP_BAD_SQLSTATE`
        public static let SP_BAD_SQLSTATE: ErrorCode = 1407
        /// `ER_STARTUP`
        public static let STARTUP: ErrorCode = 1408
        /// `ER_LOAD_FROM_FIXED_SIZE_ROWS_TO_VAR`
        public static let LOAD_FROM_FIXED_SIZE_ROWS_TO_VAR: ErrorCode = 1409
        /// `ER_CANT_CREATE_USER_WITH_GRANT`
        public static let CANT_CREATE_USER_WITH_GRANT: ErrorCode = 1410
        /// `ER_WRONG_VALUE_FOR_TYPE`
        public static let WRONG_VALUE_FOR_TYPE: ErrorCode = 1411
        /// `ER_TABLE_DEF_CHANGED`
        public static let TABLE_DEF_CHANGED: ErrorCode = 1412
        /// `ER_SP_DUP_HANDLER`
        public static let SP_DUP_HANDLER: ErrorCode = 1413
        /// `ER_SP_NOT_VAR_ARG`
        public static let SP_NOT_VAR_ARG: ErrorCode = 1414
        /// `ER_SP_NO_RETSET`
        public static let SP_NO_RETSET: ErrorCode = 1415
        /// `ER_CANT_CREATE_GEOMETRY_OBJECT`
        public static let CANT_CREATE_GEOMETRY_OBJECT: ErrorCode = 1416
        /// `ER_FAILED_ROUTINE_BREAK_BINLOG`
        public static let FAILED_ROUTINE_BREAK_BINLOG: ErrorCode = 1417
        /// `ER_BINLOG_UNSAFE_ROUTINE`
        public static let BINLOG_UNSAFE_ROUTINE: ErrorCode = 1418
        /// `ER_BINLOG_CREATE_ROUTINE_NEED_SUPER`
        public static let BINLOG_CREATE_ROUTINE_NEED_SUPER: ErrorCode = 1419
        /// `ER_EXEC_STMT_WITH_OPEN_CURSOR`
        public static let EXEC_STMT_WITH_OPEN_CURSOR: ErrorCode = 1420
        /// `ER_STMT_HAS_NO_OPEN_CURSOR`
        public static let STMT_HAS_NO_OPEN_CURSOR: ErrorCode = 1421
        /// `ER_COMMIT_NOT_ALLOWED_IN_SF_OR_TRG`
        public static let COMMIT_NOT_ALLOWED_IN_SF_OR_TRG: ErrorCode = 1422
        /// `ER_NO_DEFAULT_FOR_VIEW_FIELD`
        public static let NO_DEFAULT_FOR_VIEW_FIELD: ErrorCode = 1423
        /// `ER_SP_NO_RECURSION`
        public static let SP_NO_RECURSION: ErrorCode = 1424
        /// `ER_TOO_BIG_SCALE`
        public static let TOO_BIG_SCALE: ErrorCode = 1425
        /// `ER_TOO_BIG_PRECISION`
        public static let TOO_BIG_PRECISION: ErrorCode = 1426
        /// `ER_M_BIGGER_THAN_D`
        public static let M_BIGGER_THAN_D: ErrorCode = 1427
        /// `ER_WRONG_LOCK_OF_SYSTEM_TABLE`
        public static let WRONG_LOCK_OF_SYSTEM_TABLE: ErrorCode = 1428
        /// `ER_CONNECT_TO_FOREIGN_DATA_SOURCE`
        public static let CONNECT_TO_FOREIGN_DATA_SOURCE: ErrorCode = 1429
        /// `ER_QUERY_ON_FOREIGN_DATA_SOURCE`
        public static let QUERY_ON_FOREIGN_DATA_SOURCE: ErrorCode = 1430
        /// `ER_FOREIGN_DATA_SOURCE_DOESNT_EXIST`
        public static let FOREIGN_DATA_SOURCE_DOESNT_EXIST: ErrorCode = 1431
        /// `ER_FOREIGN_DATA_STRING_INVALID_CANT_CREATE`
        public static let FOREIGN_DATA_STRING_INVALID_CANT_CREATE: ErrorCode = 1432
        /// `ER_FOREIGN_DATA_STRING_INVALID`
        public static let FOREIGN_DATA_STRING_INVALID: ErrorCode = 1433
        /// `ER_CANT_CREATE_FEDERATED_TABLE`
        public static let CANT_CREATE_FEDERATED_TABLE: ErrorCode = 1434
        /// `ER_TRG_IN_WRONG_SCHEMA`
        public static let TRG_IN_WRONG_SCHEMA: ErrorCode = 1435
        /// `ER_STACK_OVERRUN_NEED_MORE`
        public static let STACK_OVERRUN_NEED_MORE: ErrorCode = 1436
        /// `ER_TOO_LONG_BODY`
        public static let TOO_LONG_BODY: ErrorCode = 1437
        /// `ER_WARN_CANT_DROP_DEFAULT_KEYCACHE`
        public static let WARN_CANT_DROP_DEFAULT_KEYCACHE: ErrorCode = 1438
        /// `ER_TOO_BIG_DISPLAYWIDTH`
        public static let TOO_BIG_DISPLAYWIDTH: ErrorCode = 1439
        /// `ER_XAER_DUPID`
        public static let XAER_DUPID: ErrorCode = 1440
        /// `ER_DATETIME_FUNCTION_OVERFLOW`
        public static let DATETIME_FUNCTION_OVERFLOW: ErrorCode = 1441
        /// `ER_CANT_UPDATE_USED_TABLE_IN_SF_OR_TRG`
        public static let CANT_UPDATE_USED_TABLE_IN_SF_OR_TRG: ErrorCode = 1442
        /// `ER_VIEW_PREVENT_UPDATE`
        public static let VIEW_PREVENT_UPDATE: ErrorCode = 1443
        /// `ER_PS_NO_RECURSION`
        public static let PS_NO_RECURSION: ErrorCode = 1444
        /// `ER_SP_CANT_SET_AUTOCOMMIT`
        public static let SP_CANT_SET_AUTOCOMMIT: ErrorCode = 1445
        /// `ER_MALFORMED_DEFINER`
        public static let MALFORMED_DEFINER: ErrorCode = 1446
        /// `ER_VIEW_FRM_NO_USER`
        public static let VIEW_FRM_NO_USER: ErrorCode = 1447
        /// `ER_VIEW_OTHER_USER`
        public static let VIEW_OTHER_USER: ErrorCode = 1448
        /// `ER_NO_SUCH_USER`
        public static let NO_SUCH_USER: ErrorCode = 1449
        /// `ER_FORBID_SCHEMA_CHANGE`
        public static let FORBID_SCHEMA_CHANGE: ErrorCode = 1450
        /// `ER_ROW_IS_REFERENCED_2`
        public static let ROW_IS_REFERENCED_2: ErrorCode  = 1451
        /// `ER_NO_REFERENCED_ROW_2`
        public static let NO_REFERENCED_ROW_2: ErrorCode  = 1452
        /// `ER_SP_BAD_VAR_SHADOW`
        public static let SP_BAD_VAR_SHADOW: ErrorCode = 1453
        /// `ER_TRG_NO_DEFINER`
        public static let TRG_NO_DEFINER: ErrorCode = 1454
        /// `ER_OLD_FILE_FORMAT`
        public static let OLD_FILE_FORMAT: ErrorCode = 1455
        /// `ER_SP_RECURSION_LIMIT`
        public static let SP_RECURSION_LIMIT: ErrorCode = 1456
        /// `ER_SP_PROC_TABLE_CORRUPT`
        public static let SP_PROC_TABLE_CORRUPT: ErrorCode = 1457
        /// `ER_SP_WRONG_NAME`
        public static let SP_WRONG_NAME: ErrorCode = 1458
        /// `ER_TABLE_NEEDS_UPGRADE`
        public static let TABLE_NEEDS_UPGRADE: ErrorCode = 1459
        /// `ER_SP_NO_AGGREGATE`
        public static let SP_NO_AGGREGATE: ErrorCode = 1460
        /// `ER_MAX_PREPARED_STMT_COUNT_REACHED`
        public static let MAX_PREPARED_STMT_COUNT_REACHED: ErrorCode = 1461
        /// `ER_VIEW_RECURSIVE`
        public static let VIEW_RECURSIVE: ErrorCode = 1462
        /// `ER_NON_GROUPING_FIELD_USED`
        public static let NON_GROUPING_FIELD_USED: ErrorCode = 1463
        /// `ER_TABLE_CANT_HANDLE_SPKEYS`
        public static let TABLE_CANT_HANDLE_SPKEYS: ErrorCode = 1464
        /// `ER_NO_TRIGGERS_ON_SYSTEM_SCHEMA`
        public static let NO_TRIGGERS_ON_SYSTEM_SCHEMA: ErrorCode = 1465
        /// `ER_REMOVED_SPACES`
        public static let REMOVED_SPACES: ErrorCode = 1466
        /// `ER_AUTOINC_READ_FAILED`
        public static let AUTOINC_READ_FAILED: ErrorCode = 1467
        /// `ER_USERNAME`
        public static let USERNAME: ErrorCode = 1468
        /// `ER_HOSTNAME`
        public static let HOSTNAME: ErrorCode = 1469
        /// `ER_WRONG_STRING_LENGTH`
        public static let WRONG_STRING_LENGTH: ErrorCode = 1470
        /// `ER_NON_INSERTABLE_TABLE`
        public static let NON_INSERTABLE_TABLE: ErrorCode = 1471
        /// `ER_ADMIN_WRONG_MRG_TABLE`
        public static let ADMIN_WRONG_MRG_TABLE: ErrorCode = 1472
        /// `ER_TOO_HIGH_LEVEL_OF_NESTING_FOR_SELECT`
        public static let TOO_HIGH_LEVEL_OF_NESTING_FOR_SELECT: ErrorCode = 1473
        /// `ER_NAME_BECOMES_EMPTY`
        public static let NAME_BECOMES_EMPTY: ErrorCode = 1474
        /// `ER_AMBIGUOUS_FIELD_TERM`
        public static let AMBIGUOUS_FIELD_TERM: ErrorCode = 1475
        /// `ER_FOREIGN_SERVER_EXISTS`
        public static let FOREIGN_SERVER_EXISTS: ErrorCode = 1476
        /// `ER_FOREIGN_SERVER_DOESNT_EXIST`
        public static let FOREIGN_SERVER_DOESNT_EXIST: ErrorCode = 1477
        /// `ER_ILLEGAL_HA_CREATE_OPTION`
        public static let ILLEGAL_HA_CREATE_OPTION: ErrorCode = 1478
        /// `ER_PARTITION_REQUIRES_VALUES_ERROR`
        public static let PARTITION_REQUIRES_VALUES_ERROR: ErrorCode = 1479
        /// `ER_PARTITION_WRONG_VALUES_ERROR`
        public static let PARTITION_WRONG_VALUES_ERROR: ErrorCode = 1480
        /// `ER_PARTITION_MAXVALUE_ERROR`
        public static let PARTITION_MAXVALUE_ERROR: ErrorCode = 1481
        /// `ER_PARTITION_SUBPARTITION_ERROR`
        public static let PARTITION_SUBPARTITION_ERROR: ErrorCode = 1482
        /// `ER_PARTITION_SUBPART_MIX_ERROR`
        public static let PARTITION_SUBPART_MIX_ERROR: ErrorCode = 1483
        /// `ER_PARTITION_WRONG_NO_PART_ERROR`
        public static let PARTITION_WRONG_NO_PART_ERROR: ErrorCode = 1484
        /// `ER_PARTITION_WRONG_NO_SUBPART_ERROR`
        public static let PARTITION_WRONG_NO_SUBPART_ERROR: ErrorCode = 1485
        /// `ER_WRONG_EXPR_IN_PARTITION_FUNC_ERROR`
        public static let WRONG_EXPR_IN_PARTITION_FUNC_ERROR: ErrorCode = 1486
        /// `ER_NO_CONST_EXPR_IN_RANGE_OR_LIST_ERROR`
        public static let NO_CONST_EXPR_IN_RANGE_OR_LIST_ERROR: ErrorCode = 1487
        /// `ER_FIELD_NOT_FOUND_PART_ERROR`
        public static let FIELD_NOT_FOUND_PART_ERROR: ErrorCode = 1488
        /// `ER_LIST_OF_FIELDS_ONLY_IN_HASH_ERROR`
        public static let LIST_OF_FIELDS_ONLY_IN_HASH_ERROR: ErrorCode = 1489
        /// `ER_INCONSISTENT_PARTITION_INFO_ERROR`
        public static let INCONSISTENT_PARTITION_INFO_ERROR: ErrorCode = 1490
        /// `ER_PARTITION_FUNC_NOT_ALLOWED_ERROR`
        public static let PARTITION_FUNC_NOT_ALLOWED_ERROR: ErrorCode = 1491
        /// `ER_PARTITIONS_MUST_BE_DEFINED_ERROR`
        public static let PARTITIONS_MUST_BE_DEFINED_ERROR: ErrorCode = 1492
        /// `ER_RANGE_NOT_INCREASING_ERROR`
        public static let RANGE_NOT_INCREASING_ERROR: ErrorCode = 1493
        /// `ER_INCONSISTENT_TYPE_OF_FUNCTIONS_ERROR`
        public static let INCONSISTENT_TYPE_OF_FUNCTIONS_ERROR: ErrorCode = 1494
        /// `ER_MULTIPLE_DEF_CONST_IN_LIST_PART_ERROR`
        public static let MULTIPLE_DEF_CONST_IN_LIST_PART_ERROR: ErrorCode = 1495
        /// `ER_PARTITION_ENTRY_ERROR`
        public static let PARTITION_ENTRY_ERROR: ErrorCode = 1496
        /// `ER_MIX_HANDLER_ERROR`
        public static let MIX_HANDLER_ERROR: ErrorCode = 1497
        /// `ER_PARTITION_NOT_DEFINED_ERROR`
        public static let PARTITION_NOT_DEFINED_ERROR: ErrorCode = 1498
        /// `ER_TOO_MANY_PARTITIONS_ERROR`
        public static let TOO_MANY_PARTITIONS_ERROR: ErrorCode = 1499
        /// `ER_SUBPARTITION_ERROR`
        public static let SUBPARTITION_ERROR: ErrorCode = 1500
        /// `ER_CANT_CREATE_HANDLER_FILE`
        public static let CANT_CREATE_HANDLER_FILE: ErrorCode = 1501
        /// `ER_BLOB_FIELD_IN_PART_FUNC_ERROR`
        public static let BLOB_FIELD_IN_PART_FUNC_ERROR: ErrorCode = 1502
        /// `ER_UNIQUE_KEY_NEED_ALL_FIELDS_IN_PF`
        public static let UNIQUE_KEY_NEED_ALL_FIELDS_IN_PF: ErrorCode = 1503
        /// `ER_NO_PARTS_ERROR`
        public static let NO_PARTS_ERROR: ErrorCode = 1504
        /// `ER_PARTITION_MGMT_ON_NONPARTITIONED`
        public static let PARTITION_MGMT_ON_NONPARTITIONED: ErrorCode = 1505
        /// `ER_FOREIGN_KEY_ON_PARTITIONED`
        public static let FOREIGN_KEY_ON_PARTITIONED: ErrorCode = 1506
        /// `ER_DROP_PARTITION_NON_EXISTENT`
        public static let DROP_PARTITION_NON_EXISTENT: ErrorCode = 1507
        /// `ER_DROP_LAST_PARTITION`
        public static let DROP_LAST_PARTITION: ErrorCode = 1508
        /// `ER_COALESCE_ONLY_ON_HASH_PARTITION`
        public static let COALESCE_ONLY_ON_HASH_PARTITION: ErrorCode = 1509
        /// `ER_REORG_HASH_ONLY_ON_SAME_NO`
        public static let REORG_HASH_ONLY_ON_SAME_NO: ErrorCode = 1510
        /// `ER_REORG_NO_PARAM_ERROR`
        public static let REORG_NO_PARAM_ERROR: ErrorCode = 1511
        /// `ER_ONLY_ON_RANGE_LIST_PARTITION`
        public static let ONLY_ON_RANGE_LIST_PARTITION: ErrorCode = 1512
        /// `ER_ADD_PARTITION_SUBPART_ERROR`
        public static let ADD_PARTITION_SUBPART_ERROR: ErrorCode = 1513
        /// `ER_ADD_PARTITION_NO_NEW_PARTITION`
        public static let ADD_PARTITION_NO_NEW_PARTITION: ErrorCode = 1514
        /// `ER_COALESCE_PARTITION_NO_PARTITION`
        public static let COALESCE_PARTITION_NO_PARTITION: ErrorCode = 1515
        /// `ER_REORG_PARTITION_NOT_EXIST`
        public static let REORG_PARTITION_NOT_EXIST: ErrorCode = 1516
        /// `ER_SAME_NAME_PARTITION`
        public static let SAME_NAME_PARTITION: ErrorCode = 1517
        /// `ER_NO_BINLOG_ERROR`
        public static let NO_BINLOG_ERROR: ErrorCode = 1518
        /// `ER_CONSECUTIVE_REORG_PARTITIONS`
        public static let CONSECUTIVE_REORG_PARTITIONS: ErrorCode = 1519
        /// `ER_REORG_OUTSIDE_RANGE`
        public static let REORG_OUTSIDE_RANGE: ErrorCode = 1520
        /// `ER_PARTITION_FUNCTION_FAILURE`
        public static let PARTITION_FUNCTION_FAILURE: ErrorCode = 1521
        /// `ER_PART_STATE_ERROR`
        public static let PART_STATE_ERROR: ErrorCode = 1522
        /// `ER_LIMITED_PART_RANGE`
        public static let LIMITED_PART_RANGE: ErrorCode = 1523
        /// `ER_PLUGIN_IS_NOT_LOADED`
        public static let PLUGIN_IS_NOT_LOADED: ErrorCode = 1524
        /// `ER_WRONG_VALUE`
        public static let WRONG_VALUE: ErrorCode = 1525
        /// `ER_NO_PARTITION_FOR_GIVEN_VALUE`
        public static let NO_PARTITION_FOR_GIVEN_VALUE: ErrorCode = 1526
        /// `ER_FILEGROUP_OPTION_ONLY_ONCE`
        public static let FILEGROUP_OPTION_ONLY_ONCE: ErrorCode = 1527
        /// `ER_CREATE_FILEGROUP_FAILED`
        public static let CREATE_FILEGROUP_FAILED: ErrorCode = 1528
        /// `ER_DROP_FILEGROUP_FAILED`
        public static let DROP_FILEGROUP_FAILED: ErrorCode = 1529
        /// `ER_TABLESPACE_AUTO_EXTEND_ERROR`
        public static let TABLESPACE_AUTO_EXTEND_ERROR: ErrorCode = 1530
        /// `ER_WRONG_SIZE_NUMBER`
        public static let WRONG_SIZE_NUMBER: ErrorCode = 1531
        /// `ER_SIZE_OVERFLOW_ERROR`
        public static let SIZE_OVERFLOW_ERROR: ErrorCode = 1532
        /// `ER_ALTER_FILEGROUP_FAILED`
        public static let ALTER_FILEGROUP_FAILED: ErrorCode = 1533
        /// `ER_BINLOG_ROW_LOGGING_FAILED`
        public static let BINLOG_ROW_LOGGING_FAILED: ErrorCode = 1534
        /// `ER_BINLOG_ROW_WRONG_TABLE_DEF`
        public static let BINLOG_ROW_WRONG_TABLE_DEF: ErrorCode = 1535
        /// `ER_BINLOG_ROW_RBR_TO_SBR`
        public static let BINLOG_ROW_RBR_TO_SBR: ErrorCode = 1536
        /// `ER_EVENT_ALREADY_EXISTS`
        public static let EVENT_ALREADY_EXISTS: ErrorCode = 1537
        /// `ER_EVENT_STORE_FAILED`
        public static let EVENT_STORE_FAILED: ErrorCode = 1538
        /// `ER_EVENT_DOES_NOT_EXIST`
        public static let EVENT_DOES_NOT_EXIST: ErrorCode = 1539
        /// `ER_EVENT_CANT_ALTER`
        public static let EVENT_CANT_ALTER: ErrorCode = 1540
        /// `ER_EVENT_DROP_FAILED`
        public static let EVENT_DROP_FAILED: ErrorCode = 1541
        /// `ER_EVENT_INTERVAL_NOT_POSITIVE_OR_TOO_BIG`
        public static let EVENT_INTERVAL_NOT_POSITIVE_OR_TOO_BIG: ErrorCode = 1542
        /// `ER_EVENT_ENDS_BEFORE_STARTS`
        public static let EVENT_ENDS_BEFORE_STARTS: ErrorCode = 1543
        /// `ER_EVENT_EXEC_TIME_IN_THE_PAST`
        public static let EVENT_EXEC_TIME_IN_THE_PAST: ErrorCode = 1544
        /// `ER_EVENT_OPEN_TABLE_FAILED`
        public static let EVENT_OPEN_TABLE_FAILED: ErrorCode = 1545
        /// `ER_EVENT_NEITHER_M_EXPR_NOR_M_AT`
        public static let EVENT_NEITHER_M_EXPR_NOR_M_AT: ErrorCode = 1546
        /// `ER_OBSOLETE_COL_COUNT_DOESNT_MATCH_CORRUPTED`
        public static let OBSOLETE_COL_COUNT_DOESNT_MATCH_CORRUPTED: ErrorCode = 1547
        /// `ER_OBSOLETE_CANNOT_LOAD_FROM_TABLE`
        public static let OBSOLETE_CANNOT_LOAD_FROM_TABLE: ErrorCode = 1548
        /// `ER_EVENT_CANNOT_DELETE`
        public static let EVENT_CANNOT_DELETE: ErrorCode = 1549
        /// `ER_EVENT_COMPILE_ERROR`
        public static let EVENT_COMPILE_ERROR: ErrorCode = 1550
        /// `ER_EVENT_SAME_NAME`
        public static let EVENT_SAME_NAME: ErrorCode = 1551
        /// `ER_EVENT_DATA_TOO_LONG`
        public static let EVENT_DATA_TOO_LONG: ErrorCode = 1552
        /// `ER_DROP_INDEX_FK`
        public static let DROP_INDEX_FK: ErrorCode = 1553
        /// `ER_WARN_DEPRECATED_SYNTAX_WITH_VER`
        public static let WARN_DEPRECATED_SYNTAX_WITH_VER: ErrorCode = 1554
        /// `ER_CANT_WRITE_LOCK_LOG_TABLE`
        public static let CANT_WRITE_LOCK_LOG_TABLE: ErrorCode = 1555
        /// `ER_CANT_LOCK_LOG_TABLE`
        public static let CANT_LOCK_LOG_TABLE: ErrorCode = 1556
        /// `ER_FOREIGN_DUPLICATE_KEY_OLD_UNUSED`
        public static let FOREIGN_DUPLICATE_KEY_OLD_UNUSED: ErrorCode = 1557
        /// `ER_COL_COUNT_DOESNT_MATCH_PLEASE_UPDATE`
        public static let COL_COUNT_DOESNT_MATCH_PLEASE_UPDATE: ErrorCode = 1558
        /// `ER_TEMP_TABLE_PREVENTS_SWITCH_OUT_OF_RBR`
        public static let TEMP_TABLE_PREVENTS_SWITCH_OUT_OF_RBR: ErrorCode = 1559
        /// `ER_STORED_FUNCTION_PREVENTS_SWITCH_BINLOG_FORMAT`
        public static let STORED_FUNCTION_PREVENTS_SWITCH_BINLOG_FORMAT: ErrorCode = 1560
        /// `ER_NDB_CANT_SWITCH_BINLOG_FORMAT`
        public static let NDB_CANT_SWITCH_BINLOG_FORMAT: ErrorCode = 1561
        /// `ER_PARTITION_NO_TEMPORARY`
        public static let PARTITION_NO_TEMPORARY: ErrorCode = 1562
        /// `ER_PARTITION_CONST_DOMAIN_ERROR`
        public static let PARTITION_CONST_DOMAIN_ERROR: ErrorCode = 1563
        /// `ER_PARTITION_FUNCTION_IS_NOT_ALLOWED`
        public static let PARTITION_FUNCTION_IS_NOT_ALLOWED: ErrorCode = 1564
        /// `ER_DDL_LOG_ERROR`
        public static let DDL_LOG_ERROR: ErrorCode = 1565
        /// `ER_NULL_IN_VALUES_LESS_THAN`
        public static let NULL_IN_VALUES_LESS_THAN: ErrorCode = 1566
        /// `ER_WRONG_PARTITION_NAME`
        public static let WRONG_PARTITION_NAME: ErrorCode = 1567
        /// `ER_CANT_CHANGE_TX_CHARACTERISTICS`
        public static let CANT_CHANGE_TX_CHARACTERISTICS: ErrorCode = 1568
        /// DUP_ENTRY_AUTOINCREMENT_CASE
        public static let _ENTRY_AUTOINCREMENT_CASE: ErrorCode = 1569
        /// `ER_EVENT_MODIFY_QUEUE_ERROR`
        public static let EVENT_MODIFY_QUEUE_ERROR: ErrorCode = 1570
        /// `ER_EVENT_SET_VAR_ERROR`
        public static let EVENT_SET_VAR_ERROR: ErrorCode = 1571
        /// `ER_PARTITION_MERGE_ERROR`
        public static let PARTITION_MERGE_ERROR: ErrorCode = 1572
        /// `ER_CANT_ACTIVATE_LOG`
        public static let CANT_ACTIVATE_LOG: ErrorCode = 1573
        /// `ER_RBR_NOT_AVAILABLE`
        public static let RBR_NOT_AVAILABLE: ErrorCode = 1574
        /// `ER_BASE64_DECODE_ERROR`
        public static let BASE64_DECODE_ERROR: ErrorCode = 1575
        /// `ER_EVENT_RECURSION_FORBIDDEN`
        public static let EVENT_RECURSION_FORBIDDEN: ErrorCode = 1576
        /// `ER_EVENTS_DB_ERROR`
        public static let EVENTS_DB_ERROR: ErrorCode = 1577
        /// `ER_ONLY_INTEGERS_ALLOWED`
        public static let ONLY_INTEGERS_ALLOWED: ErrorCode = 1578
        /// `ER_UNSUPORTED_LOG_ENGINE`
        public static let UNSUPORTED_LOG_ENGINE: ErrorCode = 1579
        /// `ER_BAD_LOG_STATEMENT`
        public static let BAD_LOG_STATEMENT: ErrorCode = 1580
        /// `ER_CANT_RENAME_LOG_TABLE`
        public static let CANT_RENAME_LOG_TABLE: ErrorCode = 1581
        /// `ER_WRONG_PARAMCOUNT_TO_NATIVE_FCT`
        public static let WRONG_PARAMCOUNT_TO_NATIVE_FCT: ErrorCode = 1582
        /// `ER_WRONG_PARAMETERS_TO_NATIVE_FCT`
        public static let WRONG_PARAMETERS_TO_NATIVE_FCT: ErrorCode = 1583
        /// `ER_WRONG_PARAMETERS_TO_STORED_FCT`
        public static let WRONG_PARAMETERS_TO_STORED_FCT: ErrorCode = 1584
        /// `ER_NATIVE_FCT_NAME_COLLISION`
        public static let NATIVE_FCT_NAME_COLLISION: ErrorCode = 1585
        /// `ER_DUP_ENTRY_WITH_KEY_NAME`
        public static let DUP_ENTRY_WITH_KEY_NAME: ErrorCode = 1586
        /// `ER_BINLOG_PURGE_EMFILE`
        public static let BINLOG_PURGE_EMFILE: ErrorCode = 1587
        /// `ER_EVENT_CANNOT_CREATE_IN_THE_PAST`
        public static let EVENT_CANNOT_CREATE_IN_THE_PAST: ErrorCode = 1588
        /// `ER_EVENT_CANNOT_ALTER_IN_THE_PAST`
        public static let EVENT_CANNOT_ALTER_IN_THE_PAST: ErrorCode = 1589
        /// `ER_SLAVE_INCIDENT`
        public static let SLAVE_INCIDENT: ErrorCode = 1590
        /// `ER_NO_PARTITION_FOR_GIVEN_VALUE_SILENT`
        public static let NO_PARTITION_FOR_GIVEN_VALUE_SILENT: ErrorCode = 1591
        /// `ER_BINLOG_UNSAFE_STATEMENT`
        public static let BINLOG_UNSAFE_STATEMENT: ErrorCode = 1592
        /// `ER_SLAVE_FATAL_ERROR`
        public static let SLAVE_FATAL_ERROR: ErrorCode = 1593
        /// `ER_SLAVE_RELAY_LOG_READ_FAILURE`
        public static let SLAVE_RELAY_LOG_READ_FAILURE: ErrorCode = 1594
        /// `ER_SLAVE_RELAY_LOG_WRITE_FAILURE`
        public static let SLAVE_RELAY_LOG_WRITE_FAILURE: ErrorCode = 1595
        /// `ER_SLAVE_CREATE_EVENT_FAILURE`
        public static let SLAVE_CREATE_EVENT_FAILURE: ErrorCode = 1596
        /// `ER_SLAVE_MASTER_COM_FAILURE`
        public static let SLAVE_MASTER_COM_FAILURE: ErrorCode = 1597
        /// `ER_BINLOG_LOGGING_IMPOSSIBLE`
        public static let BINLOG_LOGGING_IMPOSSIBLE: ErrorCode = 1598
        /// `ER_VIEW_NO_CREATION_CTX`
        public static let VIEW_NO_CREATION_CTX: ErrorCode = 1599
        /// `ER_VIEW_INVALID_CREATION_CTX`
        public static let VIEW_INVALID_CREATION_CTX: ErrorCode = 1600
        /// `ER_SR_INVALID_CREATION_CTX`
        public static let SR_INVALID_CREATION_CTX: ErrorCode = 1601
        /// `ER_TRG_CORRUPTED_FILE`
        public static let TRG_CORRUPTED_FILE: ErrorCode = 1602
        /// `ER_TRG_NO_CREATION_CTX`
        public static let TRG_NO_CREATION_CTX: ErrorCode = 1603
        /// `ER_TRG_INVALID_CREATION_CTX`
        public static let TRG_INVALID_CREATION_CTX: ErrorCode = 1604
        /// `ER_EVENT_INVALID_CREATION_CTX`
        public static let EVENT_INVALID_CREATION_CTX: ErrorCode = 1605
        /// `ER_TRG_CANT_OPEN_TABLE`
        public static let TRG_CANT_OPEN_TABLE: ErrorCode = 1606
        /// `ER_CANT_CREATE_SROUTINE`
        public static let CANT_CREATE_SROUTINE: ErrorCode = 1607
        /// `ER_NEVER_USED`
        public static let NEVER_USED: ErrorCode = 1608
        /// `ER_NO_FORMAT_DESCRIPTION_EVENT_BEFORE_BINLOG_STATEMENT`
        public static let NO_FORMAT_DESCRIPTION_EVENT_BEFORE_BINLOG_STATEMENT: ErrorCode = 1609
        /// `ER_SLAVE_CORRUPT_EVENT`
        public static let SLAVE_CORRUPT_EVENT: ErrorCode = 1610
        /// `ER_LOAD_DATA_INVALID_COLUMN_UNUSED`
        public static let LOAD_DATA_INVALID_COLUMN_UNUSED: ErrorCode = 1611
        /// `ER_LOG_PURGE_NO_FILE`
        public static let LOG_PURGE_NO_FILE: ErrorCode = 1612
        /// `ER_XA_RBTIMEOUT`
        public static let XA_RBTIMEOUT: ErrorCode = 1613
        /// `ER_XA_RBDEADLOCK`
        public static let XA_RBDEADLOCK: ErrorCode = 1614
        /// `ER_NEED_REPREPARE`
        public static let NEED_REPREPARE: ErrorCode = 1615
        /// `ER_DELAYED_NOT_SUPPORTED`
        public static let DELAYED_NOT_SUPPORTED: ErrorCode = 1616
        /// `WARN_NO_MASTER_INFO`
        public static let WARN_NO_MASTER_INFO: ErrorCode = 1617
        /// `WARN_OPTION_IGNORED`
        public static let WARN_OPTION_IGNORED: ErrorCode = 1618
        /// `ER_PLUGIN_DELETE_BUILTIN`
        public static let PLUGIN_DELETE_BUILTIN: ErrorCode = 1619
        /// `WARN_PLUGIN_BUSY`
        public static let WARN_PLUGIN_BUSY: ErrorCode = 1620
        /// `ER_VARIABLE_IS_READONLY`
        public static let VARIABLE_IS_READONLY: ErrorCode = 1621
        /// `ER_WARN_ENGINE_TRANSACTION_ROLLBACK`
        public static let WARN_ENGINE_TRANSACTION_ROLLBACK: ErrorCode = 1622
        /// `ER_SLAVE_HEARTBEAT_FAILURE`
        public static let SLAVE_HEARTBEAT_FAILURE: ErrorCode = 1623
        /// `ER_SLAVE_HEARTBEAT_VALUE_OUT_OF_RANGE`
        public static let SLAVE_HEARTBEAT_VALUE_OUT_OF_RANGE: ErrorCode = 1624
        /// `ER_NDB_REPLICATION_SCHEMA_ERROR`
        public static let NDB_REPLICATION_SCHEMA_ERROR: ErrorCode = 1625
        /// `ER_CONFLICT_FN_PARSE_ERROR`
        public static let CONFLICT_FN_PARSE_ERROR: ErrorCode = 1626
        /// `ER_EXCEPTIONS_WRITE_ERROR`
        public static let EXCEPTIONS_WRITE_ERROR: ErrorCode = 1627
        /// `ER_TOO_LONG_TABLE_COMMENT`
        public static let TOO_LONG_TABLE_COMMENT: ErrorCode = 1628
        /// `ER_TOO_LONG_FIELD_COMMENT`
        public static let TOO_LONG_FIELD_COMMENT: ErrorCode = 1629
        /// `ER_FUNC_INEXISTENT_NAME_COLLISION`
        public static let FUNC_INEXISTENT_NAME_COLLISION: ErrorCode = 1630
        /// `ER_DATABASE_NAME`
        public static let DATABASE_NAME: ErrorCode = 1631
        /// `ER_TABLE_NAME`
        public static let TABLE_NAME: ErrorCode = 1632
        /// `ER_PARTITION_NAME`
        public static let PARTITION_NAME: ErrorCode = 1633
        /// `ER_SUBPARTITION_NAME`
        public static let SUBPARTITION_NAME: ErrorCode = 1634
        /// `ER_TEMPORARY_NAME`
        public static let TEMPORARY_NAME: ErrorCode = 1635
        /// `ER_RENAMED_NAME`
        public static let RENAMED_NAME: ErrorCode = 1636
        /// `ER_TOO_MANY_CONCURRENT_TRXS`
        public static let TOO_MANY_CONCURRENT_TRXS: ErrorCode = 1637
        /// `WARN_NON_ASCII_SEPARATOR_NOT_IMPLEMENTED`
        public static let WARN_NON_ASCII_SEPARATOR_NOT_IMPLEMENTED: ErrorCode = 1638
        /// `ER_DEBUG_SYNC_TIMEOUT`
        public static let DEBUG_SYNC_TIMEOUT: ErrorCode = 1639
        /// `ER_DEBUG_SYNC_HIT_LIMIT`
        public static let DEBUG_SYNC_HIT_LIMIT: ErrorCode = 1640
        /// `ER_DUP_SIGNAL_SET`
        public static let DUP_SIGNAL_SET: ErrorCode = 1641
        /// `ER_SIGNAL_WARN`
        public static let SIGNAL_WARN: ErrorCode = 1642
        /// `ER_SIGNAL_NOT_FOUND`
        public static let SIGNAL_NOT_FOUND: ErrorCode = 1643
        /// `ER_SIGNAL_EXCEPTION`
        public static let SIGNAL_EXCEPTION: ErrorCode = 1644
        /// `ER_RESIGNAL_WITHOUT_ACTIVE_HANDLER`
        public static let RESIGNAL_WITHOUT_ACTIVE_HANDLER: ErrorCode = 1645
        /// `ER_SIGNAL_BAD_CONDITION_TYPE`
        public static let SIGNAL_BAD_CONDITION_TYPE: ErrorCode = 1646
        /// `WARN_COND_ITEM_TRUNCATED`
        public static let WARN_COND_ITEM_TRUNCATED: ErrorCode = 1647
        /// `ER_COND_ITEM_TOO_LONG`
        public static let COND_ITEM_TOO_LONG: ErrorCode = 1648
        /// `ER_UNKNOWN_LOCALE`
        public static let UNKNOWN_LOCALE: ErrorCode = 1649
        /// `ER_SLAVE_IGNORE_SERVER_IDS`
        public static let SLAVE_IGNORE_SERVER_IDS: ErrorCode = 1650
        /// `ER_QUERY_CACHE_DISABLED`
        public static let QUERY_CACHE_DISABLED: ErrorCode = 1651
        /// `ER_SAME_NAME_PARTITION_FIELD`
        public static let SAME_NAME_PARTITION_FIELD: ErrorCode = 1652
        /// `ER_PARTITION_COLUMN_LIST_ERROR`
        public static let PARTITION_COLUMN_LIST_ERROR: ErrorCode = 1653
        /// `ER_WRONG_TYPE_COLUMN_VALUE_ERROR`
        public static let WRONG_TYPE_COLUMN_VALUE_ERROR: ErrorCode = 1654
        /// `ER_TOO_MANY_PARTITION_FUNC_FIELDS_ERROR`
        public static let TOO_MANY_PARTITION_FUNC_FIELDS_ERROR: ErrorCode = 1655
        /// `ER_MAXVALUE_IN_VALUES_IN`
        public static let MAXVALUE_IN_VALUES_IN: ErrorCode = 1656
        /// `ER_TOO_MANY_VALUES_ERROR`
        public static let TOO_MANY_VALUES_ERROR: ErrorCode = 1657
        /// `ER_ROW_SINGLE_PARTITION_FIELD_ERROR`
        public static let ROW_SINGLE_PARTITION_FIELD_ERROR: ErrorCode = 1658
        /// `ER_FIELD_TYPE_NOT_ALLOWED_AS_PARTITION_FIELD`
        public static let FIELD_TYPE_NOT_ALLOWED_AS_PARTITION_FIELD: ErrorCode = 1659
        /// `ER_PARTITION_FIELDS_TOO_LONG`
        public static let PARTITION_FIELDS_TOO_LONG: ErrorCode = 1660
        /// `ER_BINLOG_ROW_ENGINE_AND_STMT_ENGINE`
        public static let BINLOG_ROW_ENGINE_AND_STMT_ENGINE: ErrorCode = 1661
        /// `ER_BINLOG_ROW_MODE_AND_STMT_ENGINE`
        public static let BINLOG_ROW_MODE_AND_STMT_ENGINE: ErrorCode = 1662
        /// `ER_BINLOG_UNSAFE_AND_STMT_ENGINE`
        public static let BINLOG_UNSAFE_AND_STMT_ENGINE: ErrorCode = 1663
        /// `ER_BINLOG_ROW_INJECTION_AND_STMT_ENGINE`
        public static let BINLOG_ROW_INJECTION_AND_STMT_ENGINE: ErrorCode = 1664
        /// `ER_BINLOG_STMT_MODE_AND_ROW_ENGINE`
        public static let BINLOG_STMT_MODE_AND_ROW_ENGINE: ErrorCode = 1665
        /// `ER_BINLOG_ROW_INJECTION_AND_STMT_MODE`
        public static let BINLOG_ROW_INJECTION_AND_STMT_MODE: ErrorCode = 1666
        /// `ER_BINLOG_MULTIPLE_ENGINES_AND_SELF_LOGGING_ENGINE`
        public static let BINLOG_MULTIPLE_ENGINES_AND_SELF_LOGGING_ENGINE: ErrorCode = 1667
        /// `ER_BINLOG_UNSAFE_LIMIT`
        public static let BINLOG_UNSAFE_LIMIT: ErrorCode = 1668
        /// `ER_UNUSED4`
        public static let UNUSED4: ErrorCode  = 1669
        /// `ER_BINLOG_UNSAFE_SYSTEM_TABLE`
        public static let BINLOG_UNSAFE_SYSTEM_TABLE: ErrorCode = 1670
        /// `ER_BINLOG_UNSAFE_AUTOINC_COLUMNS`
        public static let BINLOG_UNSAFE_AUTOINC_COLUMNS: ErrorCode = 1671
        /// `ER_BINLOG_UNSAFE_UDF`
        public static let BINLOG_UNSAFE_UDF: ErrorCode = 1672
        /// `ER_BINLOG_UNSAFE_SYSTEM_VARIABLE`
        public static let BINLOG_UNSAFE_SYSTEM_VARIABLE: ErrorCode = 1673
        /// `ER_BINLOG_UNSAFE_SYSTEM_FUNCTION`
        public static let BINLOG_UNSAFE_SYSTEM_FUNCTION: ErrorCode = 1674
        /// `ER_BINLOG_UNSAFE_NONTRANS_AFTER_TRANS`
        public static let BINLOG_UNSAFE_NONTRANS_AFTER_TRANS: ErrorCode = 1675
        /// `ER_MESSAGE_AND_STATEMENT`
        public static let MESSAGE_AND_STATEMENT: ErrorCode = 1676
        /// `ER_SLAVE_CONVERSION_FAILED`
        public static let SLAVE_CONVERSION_FAILED: ErrorCode = 1677
        /// `ER_SLAVE_CANT_CREATE_CONVERSION`
        public static let SLAVE_CANT_CREATE_CONVERSION: ErrorCode = 1678
        /// `ER_INSIDE_TRANSACTION_PREVENTS_SWITCH_BINLOG_FORMAT`
        public static let INSIDE_TRANSACTION_PREVENTS_SWITCH_BINLOG_FORMAT: ErrorCode = 1679
        /// `ER_PATH_LENGTH`
        public static let PATH_LENGTH: ErrorCode = 1680
        /// `ER_WARN_DEPRECATED_SYNTAX_NO_REPLACEMENT`
        public static let WARN_DEPRECATED_SYNTAX_NO_REPLACEMENT: ErrorCode = 1681
        /// `ER_WRONG_NATIVE_TABLE_STRUCTURE`
        public static let WRONG_NATIVE_TABLE_STRUCTURE: ErrorCode = 1682
        /// `ER_WRONG_PERFSCHEMA_USAGE`
        public static let WRONG_PERFSCHEMA_USAGE: ErrorCode = 1683
        /// `ER_WARN_I_S_SKIPPED_TABLE`
        public static let WARN_I_S_SKIPPED_TABLE: ErrorCode = 1684
        /// `ER_INSIDE_TRANSACTION_PREVENTS_SWITCH_BINLOG_DIRECT`
        public static let INSIDE_TRANSACTION_PREVENTS_SWITCH_BINLOG_DIRECT: ErrorCode = 1685
        /// `ER_STORED_FUNCTION_PREVENTS_SWITCH_BINLOG_DIRECT`
        public static let STORED_FUNCTION_PREVENTS_SWITCH_BINLOG_DIRECT: ErrorCode = 1686
        /// `ER_SPATIAL_MUST_HAVE_GEOM_COL`
        public static let SPATIAL_MUST_HAVE_GEOM_COL: ErrorCode = 1687
        /// `ER_TOO_LONG_INDEX_COMMENT`
        public static let TOO_LONG_INDEX_COMMENT: ErrorCode = 1688
        /// `ER_LOCK_ABORTED`
        public static let LOCK_ABORTED: ErrorCode = 1689
        /// `ER_DATA_OUT_OF_RANGE`
        public static let DATA_OUT_OF_RANGE: ErrorCode = 1690
        /// `ER_WRONG_SPVAR_TYPE_IN_LIMIT`
        public static let WRONG_SPVAR_TYPE_IN_LIMIT: ErrorCode = 1691
        /// `ER_BINLOG_UNSAFE_MULTIPLE_ENGINES_AND_SELF_LOGGING_ENGINE`
        public static let BINLOG_UNSAFE_MULTIPLE_ENGINES_AND_SELF_LOGGING_ENGINE: ErrorCode = 1692
        /// `ER_BINLOG_UNSAFE_MIXED_STATEMENT`
        public static let BINLOG_UNSAFE_MIXED_STATEMENT: ErrorCode = 1693
        /// `ER_INSIDE_TRANSACTION_PREVENTS_SWITCH_SQL_LOG_BIN`
        public static let INSIDE_TRANSACTION_PREVENTS_SWITCH_SQL_LOG_BIN: ErrorCode = 1694
        /// `ER_STORED_FUNCTION_PREVENTS_SWITCH_SQL_LOG_BIN`
        public static let STORED_FUNCTION_PREVENTS_SWITCH_SQL_LOG_BIN: ErrorCode = 1695
        /// `ER_FAILED_READ_FROM_PAR_FILE`
        public static let FAILED_READ_FROM_PAR_FILE: ErrorCode = 1696
        /// `ER_VALUES_IS_NOT_INT_TYPE_ERROR`
        public static let VALUES_IS_NOT_INT_TYPE_ERROR: ErrorCode = 1697
        /// `ER_ACCESS_DENIED_NO_PASSWORD_ERROR`
        public static let ACCESS_DENIED_NO_PASSWORD_ERROR: ErrorCode = 1698
        /// `ER_SET_PASSWORD_AUTH_PLUGIN`
        public static let SET_PASSWORD_AUTH_PLUGIN: ErrorCode = 1699
        /// `ER_GRANT_PLUGIN_USER_EXISTS`
        public static let GRANT_PLUGIN_USER_EXISTS: ErrorCode = 1700
        /// `ER_TRUNCATE_ILLEGAL_FK`
        public static let TRUNCATE_ILLEGAL_FK: ErrorCode = 1701
        /// `ER_PLUGIN_IS_PERMANENT`
        public static let PLUGIN_IS_PERMANENT: ErrorCode = 1702
        /// `ER_SLAVE_HEARTBEAT_VALUE_OUT_OF_RANGE_MIN`
        public static let SLAVE_HEARTBEAT_VALUE_OUT_OF_RANGE_MIN: ErrorCode = 1703
        /// `ER_SLAVE_HEARTBEAT_VALUE_OUT_OF_RANGE_MAX`
        public static let SLAVE_HEARTBEAT_VALUE_OUT_OF_RANGE_MAX: ErrorCode = 1704
        /// `ER_STMT_CACHE_FULL`
        public static let STMT_CACHE_FULL: ErrorCode = 1705
        /// `ER_MULTI_UPDATE_KEY_CONFLICT`
        public static let MULTI_UPDATE_KEY_CONFLICT: ErrorCode = 1706
        /// `ER_TABLE_NEEDS_REBUILD`
        public static let TABLE_NEEDS_REBUILD: ErrorCode = 1707
        /// `WARN_OPTION_BELOW_LIMIT`
        public static let WARN_OPTION_BELOW_LIMIT: ErrorCode = 1708
        /// `ER_INDEX_COLUMN_TOO_LONG`
        public static let INDEX_COLUMN_TOO_LONG: ErrorCode = 1709
        /// `ER_ERROR_IN_TRIGGER_BODY`
        public static let ERROR_IN_TRIGGER_BODY: ErrorCode = 1710
        /// `ER_ERROR_IN_UNKNOWN_TRIGGER_BODY`
        public static let ERROR_IN_UNKNOWN_TRIGGER_BODY: ErrorCode = 1711
        /// `ER_INDEX_CORRUPT`
        public static let INDEX_CORRUPT: ErrorCode = 1712
        /// `ER_UNDO_RECORD_TOO_BIG`
        public static let UNDO_RECORD_TOO_BIG: ErrorCode = 1713
        /// `ER_BINLOG_UNSAFE_INSERT_IGNORE_SELECT`
        public static let BINLOG_UNSAFE_INSERT_IGNORE_SELECT: ErrorCode = 1714
        /// `ER_BINLOG_UNSAFE_INSERT_SELECT_UPDATE`
        public static let BINLOG_UNSAFE_INSERT_SELECT_UPDATE: ErrorCode = 1715
        /// `ER_BINLOG_UNSAFE_REPLACE_SELECT`
        public static let BINLOG_UNSAFE_REPLACE_SELECT: ErrorCode = 1716
        /// `ER_BINLOG_UNSAFE_CREATE_IGNORE_SELECT`
        public static let BINLOG_UNSAFE_CREATE_IGNORE_SELECT: ErrorCode = 1717
        /// `ER_BINLOG_UNSAFE_CREATE_REPLACE_SELECT`
        public static let BINLOG_UNSAFE_CREATE_REPLACE_SELECT: ErrorCode = 1718
        /// `ER_BINLOG_UNSAFE_UPDATE_IGNORE`
        public static let BINLOG_UNSAFE_UPDATE_IGNORE: ErrorCode = 1719
        /// `ER_PLUGIN_NO_UNINSTALL`
        public static let PLUGIN_NO_UNINSTALL: ErrorCode = 1720
        /// `ER_PLUGIN_NO_INSTALL`
        public static let PLUGIN_NO_INSTALL: ErrorCode = 1721
        /// `ER_BINLOG_UNSAFE_WRITE_AUTOINC_SELECT`
        public static let BINLOG_UNSAFE_WRITE_AUTOINC_SELECT: ErrorCode = 1722
        /// `ER_BINLOG_UNSAFE_CREATE_SELECT_AUTOINC`
        public static let BINLOG_UNSAFE_CREATE_SELECT_AUTOINC: ErrorCode = 1723
        /// `ER_BINLOG_UNSAFE_INSERT_TWO_KEYS`
        public static let BINLOG_UNSAFE_INSERT_TWO_KEYS: ErrorCode = 1724
        /// `ER_TABLE_IN_FK_CHECK`
        public static let TABLE_IN_FK_CHECK: ErrorCode = 1725
        /// `ER_UNSUPPORTED_ENGINE`
        public static let UNSUPPORTED_ENGINE: ErrorCode = 1726
        /// `ER_BINLOG_UNSAFE_AUTOINC_NOT_FIRST`
        public static let BINLOG_UNSAFE_AUTOINC_NOT_FIRST: ErrorCode = 1727
        /// `ER_CANNOT_LOAD_FROM_TABLE_V2`
        public static let CANNOT_LOAD_FROM_TABLE_V2: ErrorCode  = 1728
        /// `ER_MASTER_DELAY_VALUE_OUT_OF_RANGE`
        public static let MASTER_DELAY_VALUE_OUT_OF_RANGE: ErrorCode = 1729
        /// `ER_ONLY_FD_AND_RBR_EVENTS_ALLOWED_IN_BINLOG_STATEMENT`
        public static let ONLY_FD_AND_RBR_EVENTS_ALLOWED_IN_BINLOG_STATEMENT: ErrorCode = 1730
        /// `ER_PARTITION_EXCHANGE_DIFFERENT_OPTION`
        public static let PARTITION_EXCHANGE_DIFFERENT_OPTION: ErrorCode = 1731
        /// `ER_PARTITION_EXCHANGE_PART_TABLE`
        public static let PARTITION_EXCHANGE_PART_TABLE: ErrorCode = 1732
        /// `ER_PARTITION_EXCHANGE_TEMP_TABLE`
        public static let PARTITION_EXCHANGE_TEMP_TABLE: ErrorCode = 1733
        /// `ER_PARTITION_INSTEAD_OF_SUBPARTITION`
        public static let PARTITION_INSTEAD_OF_SUBPARTITION: ErrorCode = 1734
        /// `ER_UNKNOWN_PARTITION`
        public static let UNKNOWN_PARTITION: ErrorCode = 1735
        /// `ER_TABLES_DIFFERENT_METADATA`
        public static let TABLES_DIFFERENT_METADATA: ErrorCode = 1736
        /// `ER_ROW_DOES_NOT_MATCH_PARTITION`
        public static let ROW_DOES_NOT_MATCH_PARTITION: ErrorCode = 1737
        /// `ER_BINLOG_CACHE_SIZE_GREATER_THAN_MAX`
        public static let BINLOG_CACHE_SIZE_GREATER_THAN_MAX: ErrorCode = 1738
        /// `ER_WARN_INDEX_NOT_APPLICABLE`
        public static let WARN_INDEX_NOT_APPLICABLE: ErrorCode = 1739
        /// `ER_PARTITION_EXCHANGE_FOREIGN_KEY`
        public static let PARTITION_EXCHANGE_FOREIGN_KEY: ErrorCode = 1740
        /// `ER_NO_SUCH_KEY_VALUE`
        public static let NO_SUCH_KEY_VALUE: ErrorCode = 1741
        /// `ER_RPL_INFO_DATA_TOO_LONG`
        public static let RPL_INFO_DATA_TOO_LONG: ErrorCode = 1742
        /// `ER_NETWORK_READ_EVENT_CHECKSUM_FAILURE`
        public static let NETWORK_READ_EVENT_CHECKSUM_FAILURE: ErrorCode = 1743
        /// `ER_BINLOG_READ_EVENT_CHECKSUM_FAILURE`
        public static let BINLOG_READ_EVENT_CHECKSUM_FAILURE: ErrorCode = 1744
        /// `ER_BINLOG_STMT_CACHE_SIZE_GREATER_THAN_MAX`
        public static let BINLOG_STMT_CACHE_SIZE_GREATER_THAN_MAX: ErrorCode = 1745
        /// `ER_CANT_UPDATE_TABLE_IN_CREATE_TABLE_SELECT`
        public static let CANT_UPDATE_TABLE_IN_CREATE_TABLE_SELECT: ErrorCode = 1746
        /// `ER_PARTITION_CLAUSE_ON_NONPARTITIONED`
        public static let PARTITION_CLAUSE_ON_NONPARTITIONED: ErrorCode = 1747
        /// `ER_ROW_DOES_NOT_MATCH_GIVEN_PARTITION_SET`
        public static let ROW_DOES_NOT_MATCH_GIVEN_PARTITION_SET: ErrorCode = 1748
        /// `ER_NO_SUCH_PARTITION__UNUSED`
        public static let NO_SUCH_PARTITION__UNUSED: ErrorCode = 1749
        /// `ER_CHANGE_RPL_INFO_REPOSITORY_FAILURE`
        public static let CHANGE_RPL_INFO_REPOSITORY_FAILURE: ErrorCode = 1750
        /// `ER_WARNING_NOT_COMPLETE_ROLLBACK_WITH_CREATED_TEMP_TABLE`
        public static let WARNING_NOT_COMPLETE_ROLLBACK_WITH_CREATED_TEMP_TABLE: ErrorCode = 1751
        /// `ER_WARNING_NOT_COMPLETE_ROLLBACK_WITH_DROPPED_TEMP_TABLE`
        public static let WARNING_NOT_COMPLETE_ROLLBACK_WITH_DROPPED_TEMP_TABLE: ErrorCode = 1752
        /// `ER_MTS_FEATURE_IS_NOT_SUPPORTED`
        public static let MTS_FEATURE_IS_NOT_SUPPORTED: ErrorCode = 1753
        /// `ER_MTS_UPDATED_DBS_GREATER_MAX`
        public static let MTS_UPDATED_DBS_GREATER_MAX: ErrorCode = 1754
        /// `ER_MTS_CANT_PARALLEL`
        public static let MTS_CANT_PARALLEL: ErrorCode = 1755
        /// `ER_MTS_INCONSISTENT_DATA`
        public static let MTS_INCONSISTENT_DATA: ErrorCode = 1756
        /// `ER_FULLTEXT_NOT_SUPPORTED_WITH_PARTITIONING`
        public static let FULLTEXT_NOT_SUPPORTED_WITH_PARTITIONING: ErrorCode = 1757
        /// `ER_DA_INVALID_CONDITION_NUMBER`
        public static let DA_INVALID_CONDITION_NUMBER: ErrorCode = 1758
        /// `ER_INSECURE_PLAIN_TEXT`
        public static let INSECURE_PLAIN_TEXT: ErrorCode = 1759
        /// `ER_INSECURE_CHANGE_MASTER`
        public static let INSECURE_CHANGE_MASTER: ErrorCode = 1760
        /// `ER_FOREIGN_DUPLICATE_KEY_WITH_CHILD_INFO`
        public static let FOREIGN_DUPLICATE_KEY_WITH_CHILD_INFO: ErrorCode = 1761
        /// `ER_FOREIGN_DUPLICATE_KEY_WITHOUT_CHILD_INFO`
        public static let FOREIGN_DUPLICATE_KEY_WITHOUT_CHILD_INFO: ErrorCode = 1762
        /// `ER_SQLTHREAD_WITH_SECURE_SLAVE`
        public static let SQLTHREAD_WITH_SECURE_SLAVE: ErrorCode = 1763
        /// `ER_TABLE_HAS_NO_FT`
        public static let TABLE_HAS_NO_FT: ErrorCode = 1764
        /// `ER_VARIABLE_NOT_SETTABLE_IN_SF_OR_TRIGGER`
        public static let VARIABLE_NOT_SETTABLE_IN_SF_OR_TRIGGER: ErrorCode = 1765
        /// `ER_VARIABLE_NOT_SETTABLE_IN_TRANSACTION`
        public static let VARIABLE_NOT_SETTABLE_IN_TRANSACTION: ErrorCode = 1766
        /// `ER_GTID_NEXT_IS_NOT_IN_GTID_NEXT_LIST`
        public static let GTID_NEXT_IS_NOT_IN_GTID_NEXT_LIST: ErrorCode = 1767
        /// `ER_CANT_CHANGE_GTID_NEXT_IN_TRANSACTION`
        public static let CANT_CHANGE_GTID_NEXT_IN_TRANSACTION: ErrorCode = 1768
        /// `ER_SET_STATEMENT_CANNOT_INVOKE_FUNCTION`
        public static let SET_STATEMENT_CANNOT_INVOKE_FUNCTION: ErrorCode = 1769
        /// `ER_GTID_NEXT_CANT_BE_AUTOMATIC_IF_GTID_NEXT_LIST_IS_NON_NULL`
        public static let GTID_NEXT_CANT_BE_AUTOMATIC_IF_GTID_NEXT_LIST_IS_NON_NULL: ErrorCode = 1770
        /// `ER_SKIPPING_LOGGED_TRANSACTION`
        public static let SKIPPING_LOGGED_TRANSACTION: ErrorCode = 1771
        /// `ER_MALFORMED_GTID_SET_SPECIFICATION`
        public static let MALFORMED_GTID_SET_SPECIFICATION: ErrorCode = 1772
        /// `ER_MALFORMED_GTID_SET_ENCODING`
        public static let MALFORMED_GTID_SET_ENCODING: ErrorCode = 1773
        /// `ER_MALFORMED_GTID_SPECIFICATION`
        public static let MALFORMED_GTID_SPECIFICATION: ErrorCode = 1774
        /// `ER_GNO_EXHAUSTED`
        public static let GNO_EXHAUSTED: ErrorCode = 1775
        /// `ER_BAD_SLAVE_AUTO_POSITION`
        public static let BAD_SLAVE_AUTO_POSITION: ErrorCode = 1776
        /// `ER_AUTO_POSITION_REQUIRES_GTID_MODE_NOT_OFF`
        public static let AUTO_POSITION_REQUIRES_GTID_MODE_NOT_OFF: ErrorCode = 1777
        /// `ER_CANT_DO_IMPLICIT_COMMIT_IN_TRX_WHEN_GTID_NEXT_IS_SET`
        public static let CANT_DO_IMPLICIT_COMMIT_IN_TRX_WHEN_GTID_NEXT_IS_SET: ErrorCode = 1778
        /// `ER_GTID_MODE_ON_REQUIRES_ENFORCE_GTID_CONSISTENCY_ON`
        public static let GTID_MODE_ON_REQUIRES_ENFORCE_GTID_CONSISTENCY_ON: ErrorCode = 1779
        /// `ER_GTID_MODE_REQUIRES_BINLOG`
        public static let GTID_MODE_REQUIRES_BINLOG: ErrorCode = 1780
        /// `ER_CANT_SET_GTID_NEXT_TO_GTID_WHEN_GTID_MODE_IS_OFF`
        public static let CANT_SET_GTID_NEXT_TO_GTID_WHEN_GTID_MODE_IS_OFF: ErrorCode = 1781
        /// `ER_CANT_SET_GTID_NEXT_TO_ANONYMOUS_WHEN_GTID_MODE_IS_ON`
        public static let CANT_SET_GTID_NEXT_TO_ANONYMOUS_WHEN_GTID_MODE_IS_ON: ErrorCode = 1782
        /// `ER_CANT_SET_GTID_NEXT_LIST_TO_NON_NULL_WHEN_GTID_MODE_IS_OFF`
        public static let CANT_SET_GTID_NEXT_LIST_TO_NON_NULL_WHEN_GTID_MODE_IS_OFF: ErrorCode = 1783
        /// `ER_FOUND_GTID_EVENT_WHEN_GTID_MODE_IS_OFF__UNUSED`
        public static let FOUND_GTID_EVENT_WHEN_GTID_MODE_IS_OFF__UNUSED: ErrorCode = 1784
        /// `ER_GTID_UNSAFE_NON_TRANSACTIONAL_TABLE`
        public static let GTID_UNSAFE_NON_TRANSACTIONAL_TABLE: ErrorCode = 1785
        /// `ER_GTID_UNSAFE_CREATE_SELECT`
        public static let GTID_UNSAFE_CREATE_SELECT: ErrorCode = 1786
        /// `ER_GTID_UNSAFE_CREATE_DROP_TEMPORARY_TABLE_IN_TRANSACTION`
        public static let GTID_UNSAFE_CREATE_DROP_TEMPORARY_TABLE_IN_TRANSACTION: ErrorCode = 1787
        /// `ER_GTID_MODE_CAN_ONLY_CHANGE_ONE_STEP_AT_A_TIME`
        public static let GTID_MODE_CAN_ONLY_CHANGE_ONE_STEP_AT_A_TIME: ErrorCode = 1788
        /// `ER_MASTER_HAS_PURGED_REQUIRED_GTIDS`
        public static let MASTER_HAS_PURGED_REQUIRED_GTIDS: ErrorCode = 1789
        /// `ER_CANT_SET_GTID_NEXT_WHEN_OWNING_GTID`
        public static let CANT_SET_GTID_NEXT_WHEN_OWNING_GTID: ErrorCode = 1790
        /// `ER_UNKNOWN_EXPLAIN_FORMAT`
        public static let UNKNOWN_EXPLAIN_FORMAT: ErrorCode = 1791
        /// `ER_CANT_EXECUTE_IN_READ_ONLY_TRANSACTION`
        public static let CANT_EXECUTE_IN_READ_ONLY_TRANSACTION: ErrorCode = 1792
        /// `ER_TOO_LONG_TABLE_PARTITION_COMMENT`
        public static let TOO_LONG_TABLE_PARTITION_COMMENT: ErrorCode = 1793
        /// `ER_SLAVE_CONFIGURATION`
        public static let SLAVE_CONFIGURATION: ErrorCode = 1794
        /// `ER_INNODB_FT_LIMIT`
        public static let INNODB_FT_LIMIT: ErrorCode = 1795
        /// `ER_INNODB_NO_FT_TEMP_TABLE`
        public static let INNODB_NO_FT_TEMP_TABLE: ErrorCode = 1796
        /// `ER_INNODB_FT_WRONG_DOCID_COLUMN`
        public static let INNODB_FT_WRONG_DOCID_COLUMN: ErrorCode = 1797
        /// `ER_INNODB_FT_WRONG_DOCID_INDEX`
        public static let INNODB_FT_WRONG_DOCID_INDEX: ErrorCode = 1798
        /// `ER_INNODB_ONLINE_LOG_TOO_BIG`
        public static let INNODB_ONLINE_LOG_TOO_BIG: ErrorCode = 1799
        /// `ER_UNKNOWN_ALTER_ALGORITHM`
        public static let UNKNOWN_ALTER_ALGORITHM: ErrorCode = 1800
        /// `ER_UNKNOWN_ALTER_LOCK`
        public static let UNKNOWN_ALTER_LOCK: ErrorCode = 1801
        /// `ER_MTS_CHANGE_MASTER_CANT_RUN_WITH_GAPS`
        public static let MTS_CHANGE_MASTER_CANT_RUN_WITH_GAPS: ErrorCode = 1802
        /// `ER_MTS_RECOVERY_FAILURE`
        public static let MTS_RECOVERY_FAILURE: ErrorCode = 1803
        /// `ER_MTS_RESET_WORKERS`
        public static let MTS_RESET_WORKERS: ErrorCode = 1804
        /// `ER_COL_COUNT_DOESNT_MATCH_CORRUPTED_V2`
        public static let COL_COUNT_DOESNT_MATCH_CORRUPTED_V2: ErrorCode  = 1805
        /// `ER_SLAVE_SILENT_RETRY_TRANSACTION`
        public static let SLAVE_SILENT_RETRY_TRANSACTION: ErrorCode = 1806
        /// `ER_DISCARD_FK_CHECKS_RUNNING`
        public static let DISCARD_FK_CHECKS_RUNNING: ErrorCode = 1807
        /// `ER_TABLE_SCHEMA_MISMATCH`
        public static let TABLE_SCHEMA_MISMATCH: ErrorCode = 1808
        /// `ER_TABLE_IN_SYSTEM_TABLESPACE`
        public static let TABLE_IN_SYSTEM_TABLESPACE: ErrorCode = 1809
        /// `ER_IO_READ_ERROR`
        public static let IO_READ_ERROR: ErrorCode = 1810
        /// `ER_IO_WRITE_ERROR`
        public static let IO_WRITE_ERROR: ErrorCode = 1811
        /// `ER_TABLESPACE_MISSING`
        public static let TABLESPACE_MISSING: ErrorCode = 1812
        /// `ER_TABLESPACE_EXISTS`
        public static let TABLESPACE_EXISTS: ErrorCode = 1813
        /// `ER_TABLESPACE_DISCARDED`
        public static let TABLESPACE_DISCARDED: ErrorCode = 1814
        /// `ER_INTERNAL_ERROR`
        public static let INTERNAL_ERROR: ErrorCode = 1815
        /// `ER_INNODB_IMPORT_ERROR`
        public static let INNODB_IMPORT_ERROR: ErrorCode = 1816
        /// `ER_INNODB_INDEX_CORRUPT`
        public static let INNODB_INDEX_CORRUPT: ErrorCode = 1817
        /// `ER_INVALID_YEAR_COLUMN_LENGTH`
        public static let INVALID_YEAR_COLUMN_LENGTH: ErrorCode = 1818
        /// `ER_NOT_VALID_PASSWORD`
        public static let NOT_VALID_PASSWORD: ErrorCode = 1819
        /// `ER_MUST_CHANGE_PASSWORD`
        public static let MUST_CHANGE_PASSWORD: ErrorCode = 1820
        /// `ER_FK_NO_INDEX_CHILD`
        public static let FK_NO_INDEX_CHILD: ErrorCode = 1821
        /// `ER_FK_NO_INDEX_PARENT`
        public static let FK_NO_INDEX_PARENT: ErrorCode = 1822
        /// `ER_FK_FAIL_ADD_SYSTEM`
        public static let FK_FAIL_ADD_SYSTEM: ErrorCode = 1823
        /// `ER_FK_CANNOT_OPEN_PARENT`
        public static let FK_CANNOT_OPEN_PARENT: ErrorCode = 1824
        /// `ER_FK_INCORRECT_OPTION`
        public static let FK_INCORRECT_OPTION: ErrorCode = 1825
        /// `ER_FK_DUP_NAME`
        public static let FK_DUP_NAME: ErrorCode = 1826
        /// `ER_PASSWORD_FORMAT`
        public static let PASSWORD_FORMAT: ErrorCode = 1827
        /// `ER_FK_COLUMN_CANNOT_DROP`
        public static let FK_COLUMN_CANNOT_DROP: ErrorCode = 1828
        /// `ER_FK_COLUMN_CANNOT_DROP_CHILD`
        public static let FK_COLUMN_CANNOT_DROP_CHILD: ErrorCode = 1829
        /// `ER_FK_COLUMN_NOT_NULL`
        public static let FK_COLUMN_NOT_NULL: ErrorCode = 1830
        /// `ER_DUP_INDEX`
        public static let DUP_INDEX: ErrorCode = 1831
        /// `ER_FK_COLUMN_CANNOT_CHANGE`
        public static let FK_COLUMN_CANNOT_CHANGE: ErrorCode = 1832
        /// `ER_FK_COLUMN_CANNOT_CHANGE_CHILD`
        public static let FK_COLUMN_CANNOT_CHANGE_CHILD: ErrorCode = 1833
        /// `ER_UNUSED5`
        public static let UNUSED5: ErrorCode  = 1834
        /// `ER_MALFORMED_PACKET`
        public static let MALFORMED_PACKET: ErrorCode = 1835
        /// `ER_READ_ONLY_MODE`
        public static let READ_ONLY_MODE: ErrorCode = 1836
        /// `ER_GTID_NEXT_TYPE_UNDEFINED_GROUP`
        public static let GTID_NEXT_TYPE_UNDEFINED_GROUP: ErrorCode = 1837
        /// `ER_VARIABLE_NOT_SETTABLE_IN_SP`
        public static let VARIABLE_NOT_SETTABLE_IN_SP: ErrorCode = 1838
        /// `ER_CANT_SET_GTID_PURGED_WHEN_GTID_MODE_IS_OFF`
        public static let CANT_SET_GTID_PURGED_WHEN_GTID_MODE_IS_OFF: ErrorCode = 1839
        /// `ER_CANT_SET_GTID_PURGED_WHEN_GTID_EXECUTED_IS_NOT_EMPTY`
        public static let CANT_SET_GTID_PURGED_WHEN_GTID_EXECUTED_IS_NOT_EMPTY: ErrorCode = 1840
        /// `ER_CANT_SET_GTID_PURGED_WHEN_OWNED_GTIDS_IS_NOT_EMPTY`
        public static let CANT_SET_GTID_PURGED_WHEN_OWNED_GTIDS_IS_NOT_EMPTY: ErrorCode = 1841
        /// `ER_GTID_PURGED_WAS_CHANGED`
        public static let GTID_PURGED_WAS_CHANGED: ErrorCode = 1842
        /// `ER_GTID_EXECUTED_WAS_CHANGED`
        public static let GTID_EXECUTED_WAS_CHANGED: ErrorCode = 1843
        /// `ER_BINLOG_STMT_MODE_AND_NO_REPL_TABLES`
        public static let BINLOG_STMT_MODE_AND_NO_REPL_TABLES: ErrorCode = 1844
        /// `ER_ALTER_OPERATION_NOT_SUPPORTED`
        public static let ALTER_OPERATION_NOT_SUPPORTED: ErrorCode = 1845
        /// `ER_ALTER_OPERATION_NOT_SUPPORTED_REASON`
        public static let ALTER_OPERATION_NOT_SUPPORTED_REASON: ErrorCode = 1846
        /// `ER_ALTER_OPERATION_NOT_SUPPORTED_REASON_COPY`
        public static let ALTER_OPERATION_NOT_SUPPORTED_REASON_COPY: ErrorCode = 1847
        /// `ER_ALTER_OPERATION_NOT_SUPPORTED_REASON_PARTITION`
        public static let ALTER_OPERATION_NOT_SUPPORTED_REASON_PARTITION: ErrorCode = 1848
        /// `ER_ALTER_OPERATION_NOT_SUPPORTED_REASON_FK_RENAME`
        public static let ALTER_OPERATION_NOT_SUPPORTED_REASON_FK_RENAME: ErrorCode = 1849
        /// `ER_ALTER_OPERATION_NOT_SUPPORTED_REASON_COLUMN_TYPE`
        public static let ALTER_OPERATION_NOT_SUPPORTED_REASON_COLUMN_TYPE: ErrorCode = 1850
        /// `ER_ALTER_OPERATION_NOT_SUPPORTED_REASON_FK_CHECK`
        public static let ALTER_OPERATION_NOT_SUPPORTED_REASON_FK_CHECK: ErrorCode = 1851
        /// `ER_UNUSED6`
        public static let UNUSED6: ErrorCode  = 1852
        /// `ER_ALTER_OPERATION_NOT_SUPPORTED_REASON_NOPK`
        public static let ALTER_OPERATION_NOT_SUPPORTED_REASON_NOPK: ErrorCode = 1853
        /// `ER_ALTER_OPERATION_NOT_SUPPORTED_REASON_AUTOINC`
        public static let ALTER_OPERATION_NOT_SUPPORTED_REASON_AUTOINC: ErrorCode = 1854
        /// `ER_ALTER_OPERATION_NOT_SUPPORTED_REASON_HIDDEN_FTS`
        public static let ALTER_OPERATION_NOT_SUPPORTED_REASON_HIDDEN_FTS: ErrorCode = 1855
        /// `ER_ALTER_OPERATION_NOT_SUPPORTED_REASON_CHANGE_FTS`
        public static let ALTER_OPERATION_NOT_SUPPORTED_REASON_CHANGE_FTS: ErrorCode = 1856
        /// `ER_ALTER_OPERATION_NOT_SUPPORTED_REASON_FTS`
        public static let ALTER_OPERATION_NOT_SUPPORTED_REASON_FTS: ErrorCode = 1857
        /// `ER_SQL_SLAVE_SKIP_COUNTER_NOT_SETTABLE_IN_GTID_MODE`
        public static let SQL_SLAVE_SKIP_COUNTER_NOT_SETTABLE_IN_GTID_MODE: ErrorCode = 1858
        /// `ER_DUP_UNKNOWN_IN_INDEX`
        public static let DUP_UNKNOWN_IN_INDEX: ErrorCode = 1859
        /// `ER_IDENT_CAUSES_TOO_LONG_PATH`
        public static let IDENT_CAUSES_TOO_LONG_PATH: ErrorCode = 1860
        /// `ER_ALTER_OPERATION_NOT_SUPPORTED_REASON_NOT_NULL`
        public static let ALTER_OPERATION_NOT_SUPPORTED_REASON_NOT_NULL: ErrorCode = 1861
        /// `ER_MUST_CHANGE_PASSWORD_LOGIN`
        public static let MUST_CHANGE_PASSWORD_LOGIN: ErrorCode = 1862
        /// `ER_ROW_IN_WRONG_PARTITION`
        public static let ROW_IN_WRONG_PARTITION: ErrorCode = 1863
        /// `ER_MTS_EVENT_BIGGER_PENDING_JOBS_SIZE_MAX`
        public static let MTS_EVENT_BIGGER_PENDING_JOBS_SIZE_MAX: ErrorCode = 1864
        /// `ER_INNODB_NO_FT_USES_PARSER`
        public static let INNODB_NO_FT_USES_PARSER: ErrorCode = 1865
        /// `ER_BINLOG_LOGICAL_CORRUPTION`
        public static let BINLOG_LOGICAL_CORRUPTION: ErrorCode = 1866
        /// `ER_WARN_PURGE_LOG_IN_USE`
        public static let WARN_PURGE_LOG_IN_USE: ErrorCode = 1867
        /// `ER_WARN_PURGE_LOG_IS_ACTIVE`
        public static let WARN_PURGE_LOG_IS_ACTIVE: ErrorCode = 1868
        /// `ER_AUTO_INCREMENT_CONFLICT`
        public static let AUTO_INCREMENT_CONFLICT: ErrorCode = 1869
        /// `WARN_ON_BLOCKHOLE_IN_RBR`
        public static let WARN_ON_BLOCKHOLE_IN_RBR: ErrorCode = 1870
        /// `ER_SLAVE_MI_INIT_REPOSITORY`
        public static let SLAVE_MI_INIT_REPOSITORY: ErrorCode = 1871
        /// `ER_SLAVE_RLI_INIT_REPOSITORY`
        public static let SLAVE_RLI_INIT_REPOSITORY: ErrorCode = 1872
        /// `ER_ACCESS_DENIED_CHANGE_USER_ERROR`
        public static let ACCESS_DENIED_CHANGE_USER_ERROR: ErrorCode = 1873
        /// `ER_INNODB_READ_ONLY`
        public static let INNODB_READ_ONLY: ErrorCode = 1874
        /// `ER_STOP_SLAVE_SQL_THREAD_TIMEOUT`
        public static let STOP_SLAVE_SQL_THREAD_TIMEOUT: ErrorCode = 1875
        /// `ER_STOP_SLAVE_IO_THREAD_TIMEOUT`
        public static let STOP_SLAVE_IO_THREAD_TIMEOUT: ErrorCode = 1876
        /// `ER_TABLE_CORRUPT`
        public static let TABLE_CORRUPT: ErrorCode = 1877
        /// `ER_TEMP_FILE_WRITE_FAILURE`
        public static let TEMP_FILE_WRITE_FAILURE: ErrorCode = 1878
        /// `ER_INNODB_FT_AUX_NOT_HEX_ID`
        public static let INNODB_FT_AUX_NOT_HEX_ID: ErrorCode = 1879
        /// `ER_OLD_TEMPORALS_UPGRADED`
        public static let OLD_TEMPORALS_UPGRADED: ErrorCode = 1880
        /// `ER_INNODB_FORCED_RECOVERY`
        public static let INNODB_FORCED_RECOVERY: ErrorCode = 1881
        /// `ER_AES_INVALID_IV`
        public static let AES_INVALID_IV: ErrorCode = 1882
        /// `ER_PLUGIN_CANNOT_BE_UNINSTALLED`
        public static let PLUGIN_CANNOT_BE_UNINSTALLED: ErrorCode = 1883
        /// `ER_GTID_UNSAFE_BINLOG_SPLITTABLE_STATEMENT_AND_GTID_GROUP`
        public static let GTID_UNSAFE_BINLOG_SPLITTABLE_STATEMENT_AND_GTID_GROUP: ErrorCode = 1884
        /// `ER_SLAVE_HAS_MORE_GTIDS_THAN_MASTER`
        public static let SLAVE_HAS_MORE_GTIDS_THAN_MASTER: ErrorCode = 1885
        /// `CR_UNKNOWN_ERROR`
        public static let UNKNOWN_ERROR_CLIENT: ErrorCode = 2000
        /// `CR_SOCKET_CREATE_ERROR`
        public static let SOCKET_CREATE_ERROR: ErrorCode = 2001
        /// `CR_CONNECTION_ERROR`
        public static let CONNECTION_ERROR: ErrorCode = 2002
        /// `CR_CONN_HOST_ERROR`
        public static let CONN_HOST_ERROR: ErrorCode = 2003
        /// `CR_IPSOCK_ERROR`
        public static let IPSOCK_ERROR_CLIENT: ErrorCode = 2004
        /// `CR_UNKNOWN_HOST`
        public static let UNKNOWN_HOST: ErrorCode = 2005
        /// `CR_SERVER_GONE_ERROR`
        public static let SERVER_GONE_ERROR: ErrorCode = 2006
        /// `CR_VERSION_ERROR`
        public static let VERSION_ERROR: ErrorCode = 2007
        /// `CR_OUT_OF_MEMORY`
        public static let OUT_OF_MEMORY: ErrorCode = 2008
        /// `CR_WRONG_HOST_INFO`
        public static let WRONG_HOST_INFO: ErrorCode = 2009
        /// `CR_LOCALHOST_CONNECTION`
        public static let LOCALHOST_CONNECTION: ErrorCode = 2010
        /// `CR_TCP_CONNECTION`
        public static let TCP_CONNECTION: ErrorCode = 2011
        /// `CR_SERVER_HANDSHAKE_ERR`
        public static let SERVER_HANDSHAKE_ERR: ErrorCode = 2012
        /// `CR_SERVER_LOST`
        public static let SERVER_LOST: ErrorCode = 2013
        /// `CR_COMMANDS_OUT_OF_SYNC`
        public static let COMMANDS_OUT_OF_SYNC: ErrorCode = 2014
        /// `CR_NAMEDPIPE_CONNECTION`
        public static let NAMEDPIPE_CONNECTION: ErrorCode = 2015
        /// `CR_NAMEDPIPEWAIT_ERROR`
        public static let NAMEDPIPEWAIT_ERROR: ErrorCode = 2016
        /// `CR_NAMEDPIPEOPEN_ERROR`
        public static let NAMEDPIPEOPEN_ERROR: ErrorCode = 2017
        /// `CR_NAMEDPIPESETSTATE_ERROR`
        public static let NAMEDPIPESETSTATE_ERROR: ErrorCode = 2018
        /// `CR_CANT_READ_CHARSET`
        public static let CANT_READ_CHARSET: ErrorCode = 2019
        /// `CR_NET_PACKET_TOO_LARGE`
        public static let NET_PACKET_TOO_LARGE_CLIENT: ErrorCode = 2020
        /// `CR_EMBEDDED_CONNECTION`
        public static let EMBEDDED_CONNECTION: ErrorCode = 2021
        /// `CR_PROBE_SLAVE_STATUS`
        public static let PROBE_SLAVE_STATUS: ErrorCode = 2022
        /// `CR_PROBE_SLAVE_HOSTS`
        public static let PROBE_SLAVE_HOSTS: ErrorCode = 2023
        /// `CR_PROBE_SLAVE_CONNECT`
        public static let PROBE_SLAVE_CONNECT: ErrorCode = 2024
        /// `CR_PROBE_MASTER_CONNECT`
        public static let PROBE_MASTER_CONNECT: ErrorCode = 2025
        /// `CR_SSL_CONNECTION_ERROR`
        public static let SSL_CONNECTION_ERROR: ErrorCode = 2026
        /// `CR_MALFORMED_PACKET`
        public static let MALFORMED_PACKET_CLIENT: ErrorCode = 2027
        /// `CR_WRONG_LICENSE`
        public static let WRONG_LICENSE: ErrorCode = 2028
        /// `CR_NULL_POINTER`
        public static let NULL_POINTER: ErrorCode = 2029
        /// `CR_NO_PREPARE_STMT`
        public static let NO_PREPARE_STMT: ErrorCode = 2030
        /// `CR_PARAMS_NOT_BOUND`
        public static let PARAMS_NOT_BOUND: ErrorCode = 2031
        /// `CR_DATA_TRUNCATED`
        public static let DATA_TRUNCATED: ErrorCode = 2032
        /// `CR_NO_PARAMETERS_EXISTS`
        public static let NO_PARAMETERS_EXISTS: ErrorCode = 2033
        /// `CR_INVALID_PARAMETER_NO`
        public static let INVALID_PARAMETER_NO: ErrorCode = 2034
        /// `CR_INVALID_BUFFER_USE`
        public static let INVALID_BUFFER_USE: ErrorCode = 2035
        /// `CR_UNSUPPORTED_PARAM_TYPE`
        public static let UNSUPPORTED_PARAM_TYPE: ErrorCode = 2036
        /// `CR_SHARED_MEMORY_CONNECTION`
        public static let SHARED_MEMORY_CONNECTION: ErrorCode = 2037
        /// `CR_SHARED_MEMORY_CONNECT_REQUEST_ERROR`
        public static let SHARED_MEMORY_CONNECT_REQUEST_ERROR: ErrorCode = 2038
        /// `CR_SHARED_MEMORY_CONNECT_ANSWER_ERROR`
        public static let SHARED_MEMORY_CONNECT_ANSWER_ERROR: ErrorCode = 2039
        /// `CR_SHARED_MEMORY_CONNECT_FILE_MAP_ERROR`
        public static let SHARED_MEMORY_CONNECT_FILE_MAP_ERROR: ErrorCode = 2040
        /// `CR_SHARED_MEMORY_CONNECT_MAP_ERROR`
        public static let SHARED_MEMORY_CONNECT_MAP_ERROR: ErrorCode = 2041
        /// `CR_SHARED_MEMORY_FILE_MAP_ERROR`
        public static let SHARED_MEMORY_FILE_MAP_ERROR: ErrorCode = 2042
        /// `CR_SHARED_MEMORY_MAP_ERROR`
        public static let SHARED_MEMORY_MAP_ERROR: ErrorCode = 2043
        /// `CR_SHARED_MEMORY_EVENT_ERROR`
        public static let SHARED_MEMORY_EVENT_ERROR: ErrorCode = 2044
        /// `CR_SHARED_MEMORY_CONNECT_ABANDONED_ERROR`
        public static let SHARED_MEMORY_CONNECT_ABANDONED_ERROR: ErrorCode = 2045
        /// `CR_SHARED_MEMORY_CONNECT_SET_ERROR`
        public static let SHARED_MEMORY_CONNECT_SET_ERROR: ErrorCode = 2046
        /// `CR_CONN_UNKNOW_PROTOCOL`
        public static let CONN_UNKNOW_PROTOCOL: ErrorCode = 2047
        /// `CR_INVALID_CONN_HANDLE`
        public static let INVALID_CONN_HANDLE: ErrorCode = 2048
        /// `CR_SECURE_AUTH`
        public static let SECURE_AUTH: ErrorCode = 2049
        /// `CR_FETCH_CANCELED`
        public static let FETCH_CANCELED: ErrorCode = 2050
        /// `CR_NO_DATA`
        public static let NO_DATA: ErrorCode = 2051
        /// `CR_NO_STMT_METADATA`
        public static let NO_STMT_METADATA: ErrorCode = 2052
        /// `CR_NO_RESULT_SET`
        public static let NO_RESULT_SET: ErrorCode = 2053
        /// `CR_NOT_IMPLEMENTED`
        public static let NOT_IMPLEMENTED: ErrorCode = 2054
        /// `CR_SERVER_LOST_EXTENDED`
        public static let SERVER_LOST_EXTENDED: ErrorCode = 2055
        /// `CR_STMT_CLOSED`
        public static let STMT_CLOSED: ErrorCode = 2056
        /// `CR_NEW_STMT_METADATA`
        public static let NEW_STMT_METADATA: ErrorCode = 2057
        /// `CR_ALREADY_CONNECTED`
        public static let ALREADY_CONNECTED: ErrorCode = 2058
        /// `CR_AUTH_PLUGIN_CANNOT_LOAD`
        public static let AUTH_PLUGIN_CANNOT_LOAD: ErrorCode = 2059
        /// `CR_DUPLICATE_CONNECTION_ATTR`
        public static let DUPLICATE_CONNECTION_ATTR: ErrorCode = 2060
        /// `CR_AUTH_PLUGIN_ERR`
        public static let AUTH_PLUGIN_ERR: ErrorCode = 2061
        /// `CR_INSECURE_API_ERR`
        public static let INSECURE_API_ERR: ErrorCode = 2062
        /// `ER_FILE_CORRUPT`
        public static let FILE_CORRUPT: ErrorCode = 3000
        /// `ER_ERROR_ON_MASTER`
        public static let ERROR_ON_MASTER: ErrorCode = 3001
        /// `ER_INCONSISTENT_ERROR`
        public static let INCONSISTENT_ERROR: ErrorCode = 3002
        /// `ER_STORAGE_ENGINE_NOT_LOADED`
        public static let STORAGE_ENGINE_NOT_LOADED: ErrorCode = 3003
        /// `ER_GET_STACKED_DA_WITHOUT_ACTIVE_HANDLER`
        public static let GET_STACKED_DA_WITHOUT_ACTIVE_HANDLER: ErrorCode = 3004
        /// `ER_WARN_LEGACY_SYNTAX_CONVERTED`
        public static let WARN_LEGACY_SYNTAX_CONVERTED: ErrorCode = 3005
        /// `ER_BINLOG_UNSAFE_FULLTEXT_PLUGIN`
        public static let BINLOG_UNSAFE_FULLTEXT_PLUGIN: ErrorCode = 3006
        /// `ER_CANNOT_DISCARD_TEMPORARY_TABLE`
        public static let CANNOT_DISCARD_TEMPORARY_TABLE: ErrorCode = 3007
        /// `ER_FK_DEPTH_EXCEEDED`
        public static let FK_DEPTH_EXCEEDED: ErrorCode = 3008
        /// `ER_COL_COUNT_DOESNT_MATCH_PLEASE_UPDATE_V2`
        public static let COL_COUNT_DOESNT_MATCH_PLEASE_UPDATE_V2: ErrorCode  = 3009
        /// `ER_WARN_TRIGGER_DOESNT_HAVE_CREATED`
        public static let WARN_TRIGGER_DOESNT_HAVE_CREATED: ErrorCode = 3010
        /// `ER_REFERENCED_TRG_DOES_NOT_EXIST`
        public static let REFERENCED_TRG_DOES_NOT_EXIST: ErrorCode = 3011
        /// `ER_EXPLAIN_NOT_SUPPORTED`
        public static let EXPLAIN_NOT_SUPPORTED: ErrorCode = 3012
        /// `ER_INVALID_FIELD_SIZE`
        public static let INVALID_FIELD_SIZE: ErrorCode = 3013
        /// `ER_MISSING_HA_CREATE_OPTION`
        public static let MISSING_HA_CREATE_OPTION: ErrorCode = 3014
        /// `ER_ENGINE_OUT_OF_MEMORY`
        public static let ENGINE_OUT_OF_MEMORY: ErrorCode = 3015
        /// `ER_PASSWORD_EXPIRE_ANONYMOUS_USER`
        public static let PASSWORD_EXPIRE_ANONYMOUS_USER: ErrorCode = 3016
        /// `ER_SLAVE_SQL_THREAD_MUST_STOP`
        public static let SLAVE_SQL_THREAD_MUST_STOP: ErrorCode = 3017
        /// `ER_NO_FT_MATERIALIZED_SUBQUERY`
        public static let NO_FT_MATERIALIZED_SUBQUERY: ErrorCode = 3018
        /// `ER_INNODB_UNDO_LOG_FULL`
        public static let INNODB_UNDO_LOG_FULL: ErrorCode = 3019
        /// `ER_INVALID_ARGUMENT_FOR_LOGARITHM`
        public static let INVALID_ARGUMENT_FOR_LOGARITHM: ErrorCode = 3020
        /// `ER_SLAVE_CHANNEL_IO_THREAD_MUST_STOP`
        public static let SLAVE_CHANNEL_IO_THREAD_MUST_STOP: ErrorCode = 3021
        /// `ER_WARN_OPEN_TEMP_TABLES_MUST_BE_ZERO`
        public static let WARN_OPEN_TEMP_TABLES_MUST_BE_ZERO: ErrorCode = 3022
        /// `ER_WARN_ONLY_MASTER_LOG_FILE_NO_POS`
        public static let WARN_ONLY_MASTER_LOG_FILE_NO_POS: ErrorCode = 3023
        /// `ER_QUERY_TIMEOUT`
        public static let QUERY_TIMEOUT: ErrorCode = 3024
        /// `ER_NON_RO_SELECT_DISABLE_TIMER`
        public static let NON_RO_SELECT_DISABLE_TIMER: ErrorCode = 3025
        /// `ER_DUP_LIST_ENTRY`
        public static let DUP_LIST_ENTRY: ErrorCode = 3026
        /// `ER_SQL_MODE_NO_EFFECT`
        public static let SQL_MODE_NO_EFFECT: ErrorCode = 3027
        /// `ER_AGGREGATE_ORDER_FOR_UNION`
        public static let AGGREGATE_ORDER_FOR_UNION: ErrorCode = 3028
        /// `ER_AGGREGATE_ORDER_NON_AGG_QUERY`
        public static let AGGREGATE_ORDER_NON_AGG_QUERY: ErrorCode = 3029
        /// `ER_SLAVE_WORKER_STOPPED_PREVIOUS_THD_ERROR`
        public static let SLAVE_WORKER_STOPPED_PREVIOUS_THD_ERROR: ErrorCode = 3030
        /// `ER_DONT_SUPPORT_SLAVE_PRESERVE_COMMIT_ORDER`
        public static let DONT_SUPPORT_SLAVE_PRESERVE_COMMIT_ORDER: ErrorCode = 3031
        /// `ER_SERVER_OFFLINE_MODE`
        public static let SERVER_OFFLINE_MODE: ErrorCode = 3032
        /// `ER_GIS_DIFFERENT_SRIDS`
        public static let GIS_DIFFERENT_SRIDS: ErrorCode = 3033
        /// `ER_GIS_UNSUPPORTED_ARGUMENT`
        public static let GIS_UNSUPPORTED_ARGUMENT: ErrorCode = 3034
        /// `ER_GIS_UNKNOWN_ERROR`
        public static let GIS_UNKNOWN_ERROR: ErrorCode = 3035
        /// `ER_GIS_UNKNOWN_EXCEPTION`
        public static let GIS_UNKNOWN_EXCEPTION: ErrorCode = 3036
        /// `ER_GIS_INVALID_DATA`
        public static let GIS_INVALID_DATA: ErrorCode = 3037
        /// `ER_BOOST_GEOMETRY_EMPTY_INPUT_EXCEPTION`
        public static let BOOST_GEOMETRY_EMPTY_INPUT_EXCEPTION: ErrorCode = 3038
        /// `ER_BOOST_GEOMETRY_CENTROID_EXCEPTION`
        public static let BOOST_GEOMETRY_CENTROID_EXCEPTION: ErrorCode = 3039
        /// `ER_BOOST_GEOMETRY_OVERLAY_INVALID_INPUT_EXCEPTION`
        public static let BOOST_GEOMETRY_OVERLAY_INVALID_INPUT_EXCEPTION: ErrorCode = 3040
        /// `ER_BOOST_GEOMETRY_TURN_INFO_EXCEPTION`
        public static let BOOST_GEOMETRY_TURN_INFO_EXCEPTION: ErrorCode = 3041
        /// `ER_BOOST_GEOMETRY_SELF_INTERSECTION_POINT_EXCEPTION`
        public static let BOOST_GEOMETRY_SELF_INTERSECTION_POINT_EXCEPTION: ErrorCode = 3042
        /// `ER_BOOST_GEOMETRY_UNKNOWN_EXCEPTION`
        public static let BOOST_GEOMETRY_UNKNOWN_EXCEPTION: ErrorCode = 3043
        /// `ER_STD_BAD_ALLOC_ERROR`
        public static let STD_BAD_ALLOC_ERROR: ErrorCode = 3044
        /// `ER_STD_DOMAIN_ERROR`
        public static let STD_DOMAIN_ERROR: ErrorCode = 3045
        /// `ER_STD_LENGTH_ERROR`
        public static let STD_LENGTH_ERROR: ErrorCode = 3046
        /// `ER_STD_INVALID_ARGUMENT`
        public static let STD_INVALID_ARGUMENT: ErrorCode = 3047
        /// `ER_STD_OUT_OF_RANGE_ERROR`
        public static let STD_OUT_OF_RANGE_ERROR: ErrorCode = 3048
        /// `ER_STD_OVERFLOW_ERROR`
        public static let STD_OVERFLOW_ERROR: ErrorCode = 3049
        /// `ER_STD_RANGE_ERROR`
        public static let STD_RANGE_ERROR: ErrorCode = 3050
        /// `ER_STD_UNDERFLOW_ERROR`
        public static let STD_UNDERFLOW_ERROR: ErrorCode = 3051
        /// `ER_STD_LOGIC_ERROR`
        public static let STD_LOGIC_ERROR: ErrorCode = 3052
        /// `ER_STD_RUNTIME_ERROR`
        public static let STD_RUNTIME_ERROR: ErrorCode = 3053
        /// `ER_STD_UNKNOWN_EXCEPTION`
        public static let STD_UNKNOWN_EXCEPTION: ErrorCode = 3054
        /// `ER_GIS_DATA_WRONG_ENDIANESS`
        public static let GIS_DATA_WRONG_ENDIANESS: ErrorCode = 3055
        /// `ER_CHANGE_MASTER_PASSWORD_LENGTH`
        public static let CHANGE_MASTER_PASSWORD_LENGTH: ErrorCode = 3056
        /// `ER_USER_LOCK_WRONG_NAME`
        public static let USER_LOCK_WRONG_NAME: ErrorCode = 3057
        /// `ER_USER_LOCK_DEADLOCK`
        public static let USER_LOCK_DEADLOCK: ErrorCode = 3058
        /// `ER_REPLACE_INACCESSIBLE_ROWS`
        public static let REPLACE_INACCESSIBLE_ROWS: ErrorCode = 3059
        /// `ER_ALTER_OPERATION_NOT_SUPPORTED_REASON_GIS`
        public static let ALTER_OPERATION_NOT_SUPPORTED_REASON_GIS: ErrorCode = 3060
        /// `ER_ILLEGAL_USER_VAR`
        public static let ILLEGAL_USER_VAR: ErrorCode = 3061
        /// `ER_GTID_MODE_OFF`
        public static let GTID_MODE_OFF: ErrorCode = 3062
        /// `ER_UNSUPPORTED_BY_REPLICATION_THREAD`
        public static let UNSUPPORTED_BY_REPLICATION_THREAD: ErrorCode = 3063
        /// `ER_INCORRECT_TYPE`
        public static let INCORRECT_TYPE: ErrorCode = 3064
        /// `ER_FIELD_IN_ORDER_NOT_SELECT`
        public static let FIELD_IN_ORDER_NOT_SELECT: ErrorCode = 3065
        /// `ER_AGGREGATE_IN_ORDER_NOT_SELECT`
        public static let AGGREGATE_IN_ORDER_NOT_SELECT: ErrorCode = 3066
        /// `ER_INVALID_RPL_WILD_TABLE_FILTER_PATTERN`
        public static let INVALID_RPL_WILD_TABLE_FILTER_PATTERN: ErrorCode = 3067
        /// `ER_NET_OK_PACKET_TOO_LARGE`
        public static let NET_OK_PACKET_TOO_LARGE: ErrorCode = 3068
        /// `ER_INVALID_JSON_DATA`
        public static let INVALID_JSON_DATA: ErrorCode = 3069
        /// `ER_INVALID_GEOJSON_MISSING_MEMBER`
        public static let INVALID_GEOJSON_MISSING_MEMBER: ErrorCode = 3070
        /// `ER_INVALID_GEOJSON_WRONG_TYPE`
        public static let INVALID_GEOJSON_WRONG_TYPE: ErrorCode = 3071
        /// `ER_INVALID_GEOJSON_UNSPECIFIED`
        public static let INVALID_GEOJSON_UNSPECIFIED: ErrorCode = 3072
        /// `ER_DIMENSION_UNSUPPORTED`
        public static let DIMENSION_UNSUPPORTED: ErrorCode = 3073
        /// `ER_SLAVE_CHANNEL_DOES_NOT_EXIST`
        public static let SLAVE_CHANNEL_DOES_NOT_EXIST: ErrorCode = 3074
        /// `ER_SLAVE_MULTIPLE_CHANNELS_HOST_PORT`
        public static let SLAVE_MULTIPLE_CHANNELS_HOST_PORT: ErrorCode = 3075
        /// `ER_SLAVE_CHANNEL_NAME_INVALID_OR_TOO_LONG`
        public static let SLAVE_CHANNEL_NAME_INVALID_OR_TOO_LONG: ErrorCode = 3076
        /// `ER_SLAVE_NEW_CHANNEL_WRONG_REPOSITORY`
        public static let SLAVE_NEW_CHANNEL_WRONG_REPOSITORY: ErrorCode = 3077
        /// `ER_SLAVE_CHANNEL_DELETE`
        public static let SLAVE_CHANNEL_DELETE: ErrorCode = 3078
        /// `ER_SLAVE_MULTIPLE_CHANNELS_CMD`
        public static let SLAVE_MULTIPLE_CHANNELS_CMD: ErrorCode = 3079
        /// `ER_SLAVE_MAX_CHANNELS_EXCEEDED`
        public static let SLAVE_MAX_CHANNELS_EXCEEDED: ErrorCode = 3080
        /// `ER_SLAVE_CHANNEL_MUST_STOP`
        public static let SLAVE_CHANNEL_MUST_STOP: ErrorCode = 3081
        /// `ER_SLAVE_CHANNEL_NOT_RUNNING`
        public static let SLAVE_CHANNEL_NOT_RUNNING: ErrorCode = 3082
        /// `ER_SLAVE_CHANNEL_WAS_RUNNING`
        public static let SLAVE_CHANNEL_WAS_RUNNING: ErrorCode = 3083
        /// `ER_SLAVE_CHANNEL_WAS_NOT_RUNNING`
        public static let SLAVE_CHANNEL_WAS_NOT_RUNNING: ErrorCode = 3084
        /// `ER_SLAVE_CHANNEL_SQL_THREAD_MUST_STOP`
        public static let SLAVE_CHANNEL_SQL_THREAD_MUST_STOP: ErrorCode = 3085
        /// `ER_SLAVE_CHANNEL_SQL_SKIP_COUNTER`
        public static let SLAVE_CHANNEL_SQL_SKIP_COUNTER: ErrorCode = 3086
        /// `ER_WRONG_FIELD_WITH_GROUP_V2`
        public static let WRONG_FIELD_WITH_GROUP_V2: ErrorCode  = 3087
        /// `ER_MIX_OF_GROUP_FUNC_AND_FIELDS_V2`
        public static let MIX_OF_GROUP_FUNC_AND_FIELDS_V2: ErrorCode  = 3088
        /// `ER_WARN_DEPRECATED_SYSVAR_UPDATE`
        public static let WARN_DEPRECATED_SYSVAR_UPDATE: ErrorCode = 3089
        /// `ER_WARN_DEPRECATED_SQLMODE`
        public static let WARN_DEPRECATED_SQLMODE: ErrorCode = 3090
        /// `ER_CANNOT_LOG_PARTIAL_DROP_DATABASE_WITH_GTID`
        public static let CANNOT_LOG_PARTIAL_DROP_DATABASE_WITH_GTID: ErrorCode = 3091
        /// `ER_GROUP_REPLICATION_CONFIGURATION`
        public static let GROUP_REPLICATION_CONFIGURATION: ErrorCode = 3092
        /// `ER_GROUP_REPLICATION_RUNNING`
        public static let GROUP_REPLICATION_RUNNING: ErrorCode = 3093
        /// `ER_GROUP_REPLICATION_APPLIER_INIT_ERROR`
        public static let GROUP_REPLICATION_APPLIER_INIT_ERROR: ErrorCode = 3094
        /// `ER_GROUP_REPLICATION_STOP_APPLIER_THREAD_TIMEOUT`
        public static let GROUP_REPLICATION_STOP_APPLIER_THREAD_TIMEOUT: ErrorCode = 3095
        /// `ER_GROUP_REPLICATION_COMMUNICATION_LAYER_SESSION_ERROR`
        public static let GROUP_REPLICATION_COMMUNICATION_LAYER_SESSION_ERROR: ErrorCode = 3096
        /// `ER_GROUP_REPLICATION_COMMUNICATION_LAYER_JOIN_ERROR`
        public static let GROUP_REPLICATION_COMMUNICATION_LAYER_JOIN_ERROR: ErrorCode = 3097
        /// `ER_BEFORE_DML_VALIDATION_ERROR`
        public static let BEFORE_DML_VALIDATION_ERROR: ErrorCode = 3098
        /// `ER_PREVENTS_VARIABLE_WITHOUT_RBR`
        public static let PREVENTS_VARIABLE_WITHOUT_RBR: ErrorCode = 3099
        /// `ER_RUN_HOOK_ERROR`
        public static let RUN_HOOK_ERROR: ErrorCode = 3100
        /// `ER_TRANSACTION_ROLLBACK_DURING_COMMIT`
        public static let TRANSACTION_ROLLBACK_DURING_COMMIT: ErrorCode = 3101
        /// `ER_GENERATED_COLUMN_FUNCTION_IS_NOT_ALLOWED`
        public static let GENERATED_COLUMN_FUNCTION_IS_NOT_ALLOWED: ErrorCode = 3102
        /// `ER_UNSUPPORTED_ALTER_INPLACE_ON_VIRTUAL_COLUMN`
        public static let UNSUPPORTED_ALTER_INPLACE_ON_VIRTUAL_COLUMN: ErrorCode = 3103
        /// `ER_WRONG_FK_OPTION_FOR_GENERATED_COLUMN`
        public static let WRONG_FK_OPTION_FOR_GENERATED_COLUMN: ErrorCode = 3104
        /// `ER_NON_DEFAULT_VALUE_FOR_GENERATED_COLUMN`
        public static let NON_DEFAULT_VALUE_FOR_GENERATED_COLUMN: ErrorCode = 3105
        /// `ER_UNSUPPORTED_ACTION_ON_GENERATED_COLUMN`
        public static let UNSUPPORTED_ACTION_ON_GENERATED_COLUMN: ErrorCode = 3106
        /// `ER_GENERATED_COLUMN_NON_PRIOR`
        public static let GENERATED_COLUMN_NON_PRIOR: ErrorCode = 3107
        /// `ER_DEPENDENT_BY_GENERATED_COLUMN`
        public static let DEPENDENT_BY_GENERATED_COLUMN: ErrorCode = 3108
        /// `ER_GENERATED_COLUMN_REF_AUTO_INC`
        public static let GENERATED_COLUMN_REF_AUTO_INC: ErrorCode = 3109
        /// `ER_FEATURE_NOT_AVAILABLE`
        public static let FEATURE_NOT_AVAILABLE: ErrorCode = 3110
        /// `ER_CANT_SET_GTID_MODE`
        public static let CANT_SET_GTID_MODE: ErrorCode = 3111
        /// `ER_CANT_USE_AUTO_POSITION_WITH_GTID_MODE_OFF`
        public static let CANT_USE_AUTO_POSITION_WITH_GTID_MODE_OFF: ErrorCode = 3112
        /// `ER_CANT_REPLICATE_ANONYMOUS_WITH_AUTO_POSITION`
        public static let CANT_REPLICATE_ANONYMOUS_WITH_AUTO_POSITION: ErrorCode = 3113
        /// `ER_CANT_REPLICATE_ANONYMOUS_WITH_GTID_MODE_ON`
        public static let CANT_REPLICATE_ANONYMOUS_WITH_GTID_MODE_ON: ErrorCode = 3114
        /// `ER_CANT_REPLICATE_GTID_WITH_GTID_MODE_OFF`
        public static let CANT_REPLICATE_GTID_WITH_GTID_MODE_OFF: ErrorCode = 3115
        /// `ER_CANT_SET_ENFORCE_GTID_CONSISTENCY_ON_WITH_ONGOING_GTID_VIOLATING_TRANSACTIONS`
        public static let CANT_SET_ENFORCE_GTID_CONSISTENCY_ON_WITH_ONGOING_GTID_VIOLATING_TRANSACTIONS: ErrorCode = 3116
        /// `ER_SET_ENFORCE_GTID_CONSISTENCY_WARN_WITH_ONGOING_GTID_VIOLATING_TRANSACTIONS`
        public static let SET_ENFORCE_GTID_CONSISTENCY_WARN_WITH_ONGOING_GTID_VIOLATING_TRANSACTIONS: ErrorCode = 3117
        /// `ER_ACCOUNT_HAS_BEEN_LOCKED`
        public static let ACCOUNT_HAS_BEEN_LOCKED: ErrorCode = 3118
        /// `ER_WRONG_TABLESPACE_NAME`
        public static let WRONG_TABLESPACE_NAME: ErrorCode = 3119
        /// `ER_TABLESPACE_IS_NOT_EMPTY`
        public static let TABLESPACE_IS_NOT_EMPTY: ErrorCode = 3120
        /// `ER_WRONG_FILE_NAME`
        public static let WRONG_FILE_NAME: ErrorCode = 3121
        /// `ER_BOOST_GEOMETRY_INCONSISTENT_TURNS_EXCEPTION`
        public static let BOOST_GEOMETRY_INCONSISTENT_TURNS_EXCEPTION: ErrorCode = 3122
        /// `ER_WARN_OPTIMIZER_HINT_SYNTAX_ERROR`
        public static let WARN_OPTIMIZER_HINT_SYNTAX_ERROR: ErrorCode = 3123
        /// `ER_WARN_BAD_MAX_EXECUTION_TIME`
        public static let WARN_BAD_MAX_EXECUTION_TIME: ErrorCode = 3124
        /// `ER_WARN_UNSUPPORTED_MAX_EXECUTION_TIME`
        public static let WARN_UNSUPPORTED_MAX_EXECUTION_TIME: ErrorCode = 3125
        /// `ER_WARN_CONFLICTING_HINT`
        public static let WARN_CONFLICTING_HINT: ErrorCode = 3126
        /// `ER_WARN_UNKNOWN_QB_NAME`
        public static let WARN_UNKNOWN_QB_NAME: ErrorCode = 3127
        /// `ER_UNRESOLVED_HINT_NAME`
        public static let UNRESOLVED_HINT_NAME: ErrorCode = 3128
        /// `ER_WARN_ON_MODIFYING_GTID_EXECUTED_TABLE`
        public static let WARN_ON_MODIFYING_GTID_EXECUTED_TABLE: ErrorCode = 3129
        /// `ER_PLUGGABLE_PROTOCOL_COMMAND_NOT_SUPPORTED`
        public static let PLUGGABLE_PROTOCOL_COMMAND_NOT_SUPPORTED: ErrorCode = 3130
        /// `ER_LOCKING_SERVICE_WRONG_NAME`
        public static let LOCKING_SERVICE_WRONG_NAME: ErrorCode = 3131
        /// `ER_LOCKING_SERVICE_DEADLOCK`
        public static let LOCKING_SERVICE_DEADLOCK: ErrorCode = 3132
        /// `ER_LOCKING_SERVICE_TIMEOUT`
        public static let LOCKING_SERVICE_TIMEOUT: ErrorCode = 3133
        /// `ER_GIS_MAX_POINTS_IN_GEOMETRY_OVERFLOWED`
        public static let GIS_MAX_POINTS_IN_GEOMETRY_OVERFLOWED: ErrorCode = 3134
        /// `ER_SQL_MODE_MERGED`
        public static let SQL_MODE_MERGED: ErrorCode = 3135
        /// `ER_VTOKEN_PLUGIN_TOKEN_MISMATCH`
        public static let VTOKEN_PLUGIN_TOKEN_MISMATCH: ErrorCode = 3136
        /// `ER_VTOKEN_PLUGIN_TOKEN_NOT_FOUND`
        public static let VTOKEN_PLUGIN_TOKEN_NOT_FOUND: ErrorCode = 3137
        /// `ER_CANT_SET_VARIABLE_WHEN_OWNING_GTID`
        public static let CANT_SET_VARIABLE_WHEN_OWNING_GTID: ErrorCode = 3138
        /// `ER_SLAVE_CHANNEL_OPERATION_NOT_ALLOWED`
        public static let SLAVE_CHANNEL_OPERATION_NOT_ALLOWED: ErrorCode = 3139
        /// `ER_INVALID_JSON_TEXT`
        public static let INVALID_JSON_TEXT: ErrorCode = 3140
        /// `ER_INVALID_JSON_TEXT_IN_PARAM`
        public static let INVALID_JSON_TEXT_IN_PARAM: ErrorCode = 3141
        /// `ER_INVALID_JSON_BINARY_DATA`
        public static let INVALID_JSON_BINARY_DATA: ErrorCode = 3142
        /// `ER_INVALID_JSON_PATH`
        public static let INVALID_JSON_PATH: ErrorCode = 3143
        /// `ER_INVALID_JSON_CHARSET`
        public static let INVALID_JSON_CHARSET: ErrorCode = 3144
        /// `ER_INVALID_JSON_CHARSET_IN_FUNCTION`
        public static let INVALID_JSON_CHARSET_IN_FUNCTION: ErrorCode = 3145
        /// `ER_INVALID_TYPE_FOR_JSON`
        public static let INVALID_TYPE_FOR_JSON: ErrorCode = 3146
        /// `ER_INVALID_CAST_TO_JSON`
        public static let INVALID_CAST_TO_JSON: ErrorCode = 3147
        /// `ER_INVALID_JSON_PATH_CHARSET`
        public static let INVALID_JSON_PATH_CHARSET: ErrorCode = 3148
        /// `ER_INVALID_JSON_PATH_WILDCARD`
        public static let INVALID_JSON_PATH_WILDCARD: ErrorCode = 3149
        /// `ER_JSON_VALUE_TOO_BIG`
        public static let JSON_VALUE_TOO_BIG: ErrorCode = 3150
        /// `ER_JSON_KEY_TOO_BIG`
        public static let JSON_KEY_TOO_BIG: ErrorCode = 3151
        /// `ER_JSON_USED_AS_KEY`
        public static let JSON_USED_AS_KEY: ErrorCode = 3152
        /// `ER_JSON_VACUOUS_PATH`
        public static let JSON_VACUOUS_PATH: ErrorCode = 3153
        /// `ER_JSON_BAD_ONE_OR_ALL_ARG`
        public static let JSON_BAD_ONE_OR_ALL_ARG: ErrorCode = 3154
        /// `ER_NUMERIC_JSON_VALUE_OUT_OF_RANGE`
        public static let NUMERIC_JSON_VALUE_OUT_OF_RANGE: ErrorCode = 3155
        /// `ER_INVALID_JSON_VALUE_FOR_CAST`
        public static let INVALID_JSON_VALUE_FOR_CAST: ErrorCode = 3156
        /// `ER_JSON_DOCUMENT_TOO_DEEP`
        public static let JSON_DOCUMENT_TOO_DEEP: ErrorCode = 3157
        /// `ER_JSON_DOCUMENT_NULL_KEY`
        public static let JSON_DOCUMENT_NULL_KEY: ErrorCode = 3158
        /// `ER_SECURE_TRANSPORT_REQUIRED`
        public static let SECURE_TRANSPORT_REQUIRED: ErrorCode = 3159
        /// `ER_NO_SECURE_TRANSPORTS_CONFIGURED`
        public static let NO_SECURE_TRANSPORTS_CONFIGURED: ErrorCode = 3160
        /// `ER_DISABLED_STORAGE_ENGINE`
        public static let DISABLED_STORAGE_ENGINE: ErrorCode = 3161
        /// `ER_USER_DOES_NOT_EXIST`
        public static let USER_DOES_NOT_EXIST: ErrorCode = 3162
        /// `ER_USER_ALREADY_EXISTS`
        public static let USER_ALREADY_EXISTS: ErrorCode = 3163
        /// `ER_AUDIT_API_ABORT`
        public static let AUDIT_API_ABORT: ErrorCode = 3164
        /// `ER_INVALID_JSON_PATH_ARRAY_CELL`
        public static let INVALID_JSON_PATH_ARRAY_CELL: ErrorCode = 3165
        /// `ER_BUFPOOL_RESIZE_INPROGRESS`
        public static let BUFPOOL_RESIZE_INPROGRESS: ErrorCode = 3166
        /// `ER_FEATURE_DISABLED_SEE_DOC`
        public static let FEATURE_DISABLED_SEE_DOC: ErrorCode = 3167
        /// `ER_SERVER_ISNT_AVAILABLE`
        public static let SERVER_ISNT_AVAILABLE: ErrorCode = 3168
        /// `ER_SESSION_WAS_KILLED`
        public static let SESSION_WAS_KILLED: ErrorCode = 3169
        /// `ER_CAPACITY_EXCEEDED`
        public static let CAPACITY_EXCEEDED: ErrorCode = 3170
        /// `ER_CAPACITY_EXCEEDED_IN_RANGE_OPTIMIZER`
        public static let CAPACITY_EXCEEDED_IN_RANGE_OPTIMIZER: ErrorCode = 3171
        /// `ER_TABLE_NEEDS_UPG_PART`
        public static let TABLE_NEEDS_UPG_PART: ErrorCode = 3172
        /// `ER_CANT_WAIT_FOR_EXECUTED_GTID_SET_WHILE_OWNING_A_GTID`
        public static let CANT_WAIT_FOR_EXECUTED_GTID_SET_WHILE_OWNING_A_GTID: ErrorCode = 3173
        /// `ER_CANNOT_ADD_FOREIGN_BASE_COL_VIRTUAL`
        public static let CANNOT_ADD_FOREIGN_BASE_COL_VIRTUAL: ErrorCode = 3174
        /// `ER_CANNOT_CREATE_VIRTUAL_INDEX_CONSTRAINT`
        public static let CANNOT_CREATE_VIRTUAL_INDEX_CONSTRAINT: ErrorCode = 3175
        /// `ER_ERROR_ON_MODIFYING_GTID_EXECUTED_TABLE`
        public static let ERROR_ON_MODIFYING_GTID_EXECUTED_TABLE: ErrorCode = 3176
        /// `ER_LOCK_REFUSED_BY_ENGINE`
        public static let LOCK_REFUSED_BY_ENGINE: ErrorCode = 3177
        /// `ER_UNSUPPORTED_ALTER_ONLINE_ON_VIRTUAL_COLUMN`
        public static let UNSUPPORTED_ALTER_ONLINE_ON_VIRTUAL_COLUMN: ErrorCode = 3178
        /// `ER_MASTER_KEY_ROTATION_NOT_SUPPORTED_BY_SE`
        public static let MASTER_KEY_ROTATION_NOT_SUPPORTED_BY_SE: ErrorCode = 3179
        /// `ER_MASTER_KEY_ROTATION_ERROR_BY_SE`
        public static let MASTER_KEY_ROTATION_ERROR_BY_SE: ErrorCode = 3180
        /// `ER_MASTER_KEY_ROTATION_BINLOG_FAILED`
        public static let MASTER_KEY_ROTATION_BINLOG_FAILED: ErrorCode = 3181
        /// `ER_MASTER_KEY_ROTATION_SE_UNAVAILABLE`
        public static let MASTER_KEY_ROTATION_SE_UNAVAILABLE: ErrorCode = 3182
        /// `ER_TABLESPACE_CANNOT_ENCRYPT`
        public static let TABLESPACE_CANNOT_ENCRYPT: ErrorCode = 3183
        /// `ER_INVALID_ENCRYPTION_OPTION`
        public static let INVALID_ENCRYPTION_OPTION: ErrorCode = 3184
        /// `ER_CANNOT_FIND_KEY_IN_KEYRING`
        public static let CANNOT_FIND_KEY_IN_KEYRING: ErrorCode = 3185
        /// `ER_CAPACITY_EXCEEDED_IN_PARSER`
        public static let CAPACITY_EXCEEDED_IN_PARSER: ErrorCode = 3186
        /// `ER_UNSUPPORTED_ALTER_ENCRYPTION_INPLACE`
        public static let UNSUPPORTED_ALTER_ENCRYPTION_INPLACE: ErrorCode = 3187
        /// `ER_KEYRING_UDF_KEYRING_SERVICE_ERROR`
        public static let KEYRING_UDF_KEYRING_SERVICE_ERROR: ErrorCode = 3188
        /// `ER_USER_COLUMN_OLD_LENGTH`
        public static let USER_COLUMN_OLD_LENGTH: ErrorCode = 3189
        /// `ER_CANT_RESET_MASTER`
        public static let CANT_RESET_MASTER: ErrorCode = 3190
        /// `ER_GROUP_REPLICATION_MAX_GROUP_SIZE`
        public static let GROUP_REPLICATION_MAX_GROUP_SIZE: ErrorCode = 3191
        /// `ER_CANNOT_ADD_FOREIGN_BASE_COL_STORED`
        public static let CANNOT_ADD_FOREIGN_BASE_COL_STORED: ErrorCode = 3192
        /// `ER_TABLE_REFERENCED`
        public static let TABLE_REFERENCED: ErrorCode = 3193
        
        public var rawValue: UInt16
        
        public var description: String {
            return "\(self.name) (\(self.rawValue))"
        }
        
        public var name: String {
            switch self.rawValue {
            case 1: return "SERVER_ERROR"
            case 1000: return "HASHCHK"
            case 1001: return "NISAMCHK"
            case 1002: return "NO"
            case 1003: return "YES"
            case 1004: return "CANT_CREATE_FILE"
            case 1005: return "CANT_CREATE_TABLE"
            case 1006: return "CANT_CREATE_DB"
            case 1007: return "DB_CREATE_EXISTS"
            case 1008: return "DB_DROP_EXISTS"
            case 1009: return "DB_DROP_DELETE"
            case 1010: return "DB_DROP_RMDIR"
            case 1011: return "CANT_DELETE_FILE"
            case 1012: return "CANT_FIND_SYSTEM_REC"
            case 1013: return "CANT_GET_STAT"
            case 1014: return "CANT_GET_WD"
            case 1015: return "CANT_LOCK"
            case 1016: return "CANT_OPEN_FILE"
            case 1017: return "FILE_NOT_FOUND"
            case 1018: return "CANT_READ_DIR"
            case 1019: return "CANT_SET_WD"
            case 1020: return "CHECKREAD"
            case 1021: return "DISK_FULL"
            case 1022: return "DUP_KEY"
            case 1023: return "ERROR_ON_CLOSE"
            case 1024: return "ERROR_ON_READ"
            case 1025: return "ERROR_ON_RENAME"
            case 1026: return "ERROR_ON_WRITE"
            case 1027: return "FILE_USED"
            case 1028: return "FILSORT_ABORT"
            case 1029: return "FORM_NOT_FOUND"
            case 1030: return "GET_ERRNO"
            case 1031: return "ILLEGAL_HA"
            case 1032: return "KEY_NOT_FOUND"
            case 1033: return "NOT_FORM_FILE"
            case 1034: return "NOT_KEYFILE"
            case 1035: return "OLD_KEYFILE"
            case 1036: return "OPEN_AS_READONLY"
            case 1037: return "OUTOFMEMORY"
            case 1038: return "OUT_OF_SORTMEMORY"
            case 1039: return "UNEXPECTED_EOF"
            case 1040: return "CON_COUNT_ERROR"
            case 1041: return "OUT_OF_RESOURCES"
            case 1042: return "BAD_HOST_ERROR"
            case 1043: return "HANDSHAKE_ERROR"
            case 1044: return "DBACCESS_DENIED_ERROR"
            case 1045: return "ACCESS_DENIED_ERROR"
            case 1046: return "NO_DB_ERROR"
            case 1047: return "UNKNOWN_COM_ERROR"
            case 1048: return "BAD_NULL_ERROR"
            case 1049: return "BAD_DB_ERROR"
            case 1050: return "TABLE_EXISTS_ERROR"
            case 1051: return "BAD_TABLE_ERROR"
            case 1052: return "NON_UNIQ_ERROR"
            case 1053: return "SERVER_SHUTDOWN"
            case 1054: return "BAD_FIELD_ERROR"
            case 1055: return "WRONG_FIELD_WITH_GROUP"
            case 1056: return "WRONG_GROUP_FIELD"
            case 1057: return "WRONG_SUM_SELECT"
            case 1058: return "WRONG_VALUE_COUNT"
            case 1059: return "TOO_LONG_IDENT"
            case 1060: return "DUP_FIELDNAME"
            case 1061: return "DUP_KEYNAME"
            case 1062: return "DUP_ENTRY"
            case 1063: return "WRONG_FIELD_SPEC"
            case 1064: return "PARSE_ERROR"
            case 1065: return "EMPTY_QUERY"
            case 1066: return "NONUNIQ_TABLE"
            case 1067: return "INVALID_DEFAULT"
            case 1068: return "MULTIPLE_PRI_KEY"
            case 1069: return "TOO_MANY_KEYS"
            case 1070: return "TOO_MANY_KEY_PARTS"
            case 1071: return "TOO_LONG_KEY"
            case 1072: return "KEY_COLUMN_DOES_NOT_EXITS"
            case 1073: return "BLOB_USED_AS_KEY"
            case 1074: return "TOO_BIG_FIELDLENGTH"
            case 1075: return "WRONG_AUTO_KEY"
            case 1076: return "READY"
            case 1077: return "NORMAL_SHUTDOWN"
            case 1078: return "GOT_SIGNAL"
            case 1079: return "SHUTDOWN_COMPLETE"
            case 1080: return "FORCING_CLOSE"
            case 1081: return "IPSOCK_ERROR"
            case 1082: return "NO_SUCH_INDEX"
            case 1083: return "WRONG_FIELD_TERMINATORS"
            case 1084: return "BLOBS_AND_NO_TERMINATED"
            case 1085: return "TEXTFILE_NOT_READABLE"
            case 1086: return "FILE_EXISTS_ERROR"
            case 1087: return "LOAD_INFO"
            case 1088: return "ALTER_INFO"
            case 1089: return "WRONG_SUB_KEY"
            case 1090: return "CANT_REMOVE_ALL_FIELDS"
            case 1091: return "CANT_DROP_FIELD_OR_KEY"
            case 1092: return "INSERT_INFO"
            case 1093: return "UPDATE_TABLE_USED"
            case 1094: return "NO_SUCH_THREAD"
            case 1095: return "KILL_DENIED_ERROR"
            case 1096: return "NO_TABLES_USED"
            case 1097: return "TOO_BIG_SET"
            case 1098: return "NO_UNIQUE_LOGFILE"
            case 1099: return "TABLE_NOT_LOCKED_FOR_WRITE"
            case 1100: return "TABLE_NOT_LOCKED"
            case 1101: return "BLOB_CANT_HAVE_DEFAULT"
            case 1102: return "WRONG_DB_NAME"
            case 1103: return "WRONG_TABLE_NAME"
            case 1104: return "TOO_BIG_SELECT"
            case 1105: return "UNKNOWN_ERROR"
            case 1106: return "UNKNOWN_PROCEDURE"
            case 1107: return "WRONG_PARAMCOUNT_TO_PROCEDURE"
            case 1108: return "WRONG_PARAMETERS_TO_PROCEDURE"
            case 1109: return "UNKNOWN_TABLE"
            case 1110: return "FIELD_SPECIFIED_TWICE"
            case 1111: return "INVALID_GROUP_FUNC_USE"
            case 1112: return "UNSUPPORTED_EXTENSION"
            case 1113: return "TABLE_MUST_HAVE_COLUMNS"
            case 1114: return "RECORD_FILE_FULL"
            case 1115: return "UNKNOWN_CHARACTER_SET"
            case 1116: return "TOO_MANY_TABLES"
            case 1117: return "TOO_MANY_FIELDS"
            case 1118: return "TOO_BIG_ROWSIZE"
            case 1119: return "STACK_OVERRUN"
            case 1120: return "WRONG_OUTER_JOIN"
            case 1121: return "NULL_COLUMN_IN_INDEX"
            case 1122: return "CANT_FIND_UDF"
            case 1123: return "CANT_INITIALIZE_UDF"
            case 1124: return "UDF_NO_PATHS"
            case 1125: return "UDF_EXISTS"
            case 1126: return "CANT_OPEN_LIBRARY"
            case 1127: return "CANT_FIND_DL_ENTRY"
            case 1128: return "FUNCTION_NOT_DEFINED"
            case 1129: return "HOST_IS_BLOCKED"
            case 1130: return "HOST_NOT_PRIVILEGED"
            case 1131: return "PASSWORD_ANONYMOUS_USER"
            case 1132: return "PASSWORD_NOT_ALLOWED"
            case 1133: return "PASSWORD_NO_MATCH"
            case 1134: return "UPDATE_INFO"
            case 1135: return "CANT_CREATE_THREAD"
            case 1136: return "WRONG_VALUE_COUNT_ON_ROW"
            case 1137: return "CANT_REOPEN_TABLE"
            case 1138: return "INVALID_USE_OF_NULL"
            case 1139: return "REGEXP_ERROR"
            case 1140: return "MIX_OF_GROUP_FUNC_AND_FIELDS"
            case 1141: return "NONEXISTING_GRANT"
            case 1142: return "TABLEACCESS_DENIED_ERROR"
            case 1143: return "COLUMNACCESS_DENIED_ERROR"
            case 1144: return "ILLEGAL_GRANT_FOR_TABLE"
            case 1145: return "GRANT_WRONG_HOST_OR_USER"
            case 1146: return "NO_SUCH_TABLE"
            case 1147: return "NONEXISTING_TABLE_GRANT"
            case 1148: return "NOT_ALLOWED_COMMAND"
            case 1149: return "SYNTAX_ERROR"
            case 1150: return "UNUSED1: "
            case 1151: return "UNUSED2: "
            case 1152: return "ABORTING_CONNECTION"
            case 1153: return "NET_PACKET_TOO_LARGE"
            case 1154: return "NET_READ_ERROR_FROM_PIPE"
            case 1155: return "NET_FCNTL_ERROR"
            case 1156: return "NET_PACKETS_OUT_OF_ORDER"
            case 1157: return "NET_UNCOMPRESS_ERROR"
            case 1158: return "NET_READ_ERROR"
            case 1159: return "NET_READ_INTERRUPTED"
            case 1160: return "NET_ERROR_ON_WRITE"
            case 1161: return "NET_WRITE_INTERRUPTED"
            case 1162: return "TOO_LONG_STRING"
            case 1163: return "TABLE_CANT_HANDLE_BLOB"
            case 1164: return "TABLE_CANT_HANDLE_AUTO_INCREMENT"
            case 1165: return "UNUSED3: "
            case 1166: return "WRONG_COLUMN_NAME"
            case 1167: return "WRONG_KEY_COLUMN"
            case 1168: return "WRONG_MRG_TABLE"
            case 1169: return "DUP_UNIQUE"
            case 1170: return "BLOB_KEY_WITHOUT_LENGTH"
            case 1171: return "PRIMARY_CANT_HAVE_NULL"
            case 1172: return "TOO_MANY_ROWS"
            case 1173: return "REQUIRES_PRIMARY_KEY"
            case 1174: return "NO_RAID_COMPILED"
            case 1175: return "UPDATE_WITHOUT_KEY_IN_SAFE_MODE"
            case 1176: return "KEY_DOES_NOT_EXITS"
            case 1177: return "CHECK_NO_SUCH_TABLE"
            case 1178: return "CHECK_NOT_IMPLEMENTED"
            case 1179: return "CANT_DO_THIS_DURING_AN_TRANSACTION"
            case 1180: return "ERROR_DURING_COMMIT"
            case 1181: return "ERROR_DURING_ROLLBACK"
            case 1182: return "ERROR_DURING_FLUSH_LOGS"
            case 1183: return "ERROR_DURING_CHECKPOINT"
            case 1184: return "NEW_ABORTING_CONNECTION"
            case 1185: return "DUMP_NOT_IMPLEMENTED"
            case 1186: return "FLUSH_MASTER_BINLOG_CLOSED"
            case 1187: return "INDEX_REBUILD"
            case 1188: return "MASTER"
            case 1189: return "MASTER_NET_READ"
            case 1190: return "MASTER_NET_WRITE"
            case 1191: return "FT_MATCHING_KEY_NOT_FOUND"
            case 1192: return "LOCK_OR_ACTIVE_TRANSACTION"
            case 1193: return "UNKNOWN_SYSTEM_VARIABLE"
            case 1194: return "CRASHED_ON_USAGE"
            case 1195: return "CRASHED_ON_REPAIR"
            case 1196: return "WARNING_NOT_COMPLETE_ROLLBACK"
            case 1197: return "TRANS_CACHE_FULL"
            case 1198: return "SLAVE_MUST_STOP"
            case 1199: return "SLAVE_NOT_RUNNING"
            case 1200: return "BAD_SLAVE"
            case 1201: return "MASTER_INFO"
            case 1202: return "SLAVE_THREAD"
            case 1203: return "TOO_MANY_USER_CONNECTIONS"
            case 1204: return "SET_CONSTANTS_ONLY"
            case 1205: return "LOCK_WAIT_TIMEOUT"
            case 1206: return "LOCK_TABLE_FULL"
            case 1207: return "READ_ONLY_TRANSACTION"
            case 1208: return "DROP_DB_WITH_READ_LOCK"
            case 1209: return "CREATE_DB_WITH_READ_LOCK"
            case 1210: return "WRONG_ARGUMENTS"
            case 1211: return "NO_PERMISSION_TO_CREATE_USER"
            case 1212: return "UNION_TABLES_IN_DIFFERENT_DIR"
            case 1213: return "LOCK_DEADLOCK"
            case 1214: return "TABLE_CANT_HANDLE_FT"
            case 1215: return "CANNOT_ADD_FOREIGN"
            case 1216: return "NO_REFERENCED_ROW"
            case 1217: return "ROW_IS_REFERENCED"
            case 1218: return "CONNECT_TO_MASTER"
            case 1219: return "QUERY_ON_MASTER"
            case 1220: return "ERROR_WHEN_EXECUTING_COMMAND"
            case 1221: return "WRONG_USAGE"
            case 1222: return "WRONG_NUMBER_OF_COLUMNS_IN_SELECT"
            case 1223: return "CANT_UPDATE_WITH_READLOCK"
            case 1224: return "MIXING_NOT_ALLOWED"
            case 1225: return "DUP_ARGUMENT"
            case 1226: return "USER_LIMIT_REACHED"
            case 1227: return "SPECIFIC_ACCESS_DENIED_ERROR"
            case 1228: return "LOCAL_VARIABLE"
            case 1229: return "GLOBAL_VARIABLE"
            case 1230: return "NO_DEFAULT"
            case 1231: return "WRONG_VALUE_FOR_VAR"
            case 1232: return "WRONG_TYPE_FOR_VAR"
            case 1233: return "VAR_CANT_BE_READ"
            case 1234: return "CANT_USE_OPTION_HERE"
            case 1235: return "NOT_SUPPORTED_YET"
            case 1236: return "MASTER_FATAL_ERROR_READING_BINLOG"
            case 1237: return "SLAVE_IGNORED_TABLE"
            case 1238: return "INCORRECT_GLOBAL_LOCAL_VAR"
            case 1239: return "WRONG_FK_DEF"
            case 1240: return "KEY_REF_DO_NOT_MATCH_TABLE_REF"
            case 1241: return "OPERAND_COLUMNS"
            case 1242: return "SUBQUERY_NO_1_ROW"
            case 1243: return "UNKNOWN_STMT_HANDLER"
            case 1244: return "CORRUPT_HELP_DB"
            case 1245: return "CYCLIC_REFERENCE"
            case 1246: return "AUTO_CONVERT"
            case 1247: return "ILLEGAL_REFERENCE"
            case 1248: return "DERIVED_MUST_HAVE_ALIAS"
            case 1249: return "SELECT_REDUCED"
            case 1250: return "TABLENAME_NOT_ALLOWED_HERE"
            case 1251: return "NOT_SUPPORTED_AUTH_MODE"
            case 1252: return "SPATIAL_CANT_HAVE_NULL"
            case 1253: return "COLLATION_CHARSET_MISMATCH"
            case 1254: return "SLAVE_WAS_RUNNING"
            case 1255: return "SLAVE_WAS_NOT_RUNNING"
            case 1256: return "TOO_BIG_FOR_UNCOMPRESS"
            case 1257: return "ZLIB_Z_MEM_ERROR"
            case 1258: return "ZLIB_Z_BUF_ERROR"
            case 1259: return "ZLIB_Z_DATA_ERROR"
            case 1260: return "CUT_VALUE_GROUP_CONCAT"
            case 1261: return "WARN_TOO_FEW_RECORDS"
            case 1262: return "WARN_TOO_MANY_RECORDS"
            case 1263: return "WARN_NULL_TO_NOTNULL"
            case 1264: return "WARN_DATA_OUT_OF_RANGE"
            case 1265: return "N_DATA_TRUNCATED"
            case 1266: return "WARN_USING_OTHER_HANDLER"
            case 1267: return "CANT_AGGREGATE_2COLLATIONS"
            case 1268: return "DROP_USER"
            case 1269: return "REVOKE_GRANTS"
            case 1270: return "CANT_AGGREGATE_3COLLATIONS"
            case 1271: return "CANT_AGGREGATE_NCOLLATIONS"
            case 1272: return "VARIABLE_IS_NOT_STRUCT"
            case 1273: return "UNKNOWN_COLLATION"
            case 1274: return "SLAVE_IGNORED_SSL_PARAMS"
            case 1275: return "SERVER_IS_IN_SECURE_AUTH_MODE"
            case 1276: return "WARN_FIELD_RESOLVED"
            case 1277: return "BAD_SLAVE_UNTIL_COND"
            case 1278: return "MISSING_SKIP_SLAVE"
            case 1279: return "UNTIL_COND_IGNORED"
            case 1280: return "WRONG_NAME_FOR_INDEX"
            case 1281: return "WRONG_NAME_FOR_CATALOG"
            case 1282: return "WARN_QC_RESIZE"
            case 1283: return "BAD_FT_COLUMN"
            case 1284: return "UNKNOWN_KEY_CACHE"
            case 1285: return "WARN_HOSTNAME_WONT_WORK"
            case 1286: return "UNKNOWN_STORAGE_ENGINE"
            case 1287: return "WARN_DEPRECATED_SYNTAX"
            case 1288: return "NON_UPDATABLE_TABLE"
            case 1289: return "FEATURE_DISABLED"
            case 1290: return "OPTION_PREVENTS_STATEMENT"
            case 1291: return "DUPLICATED_VALUE_IN_TYPE"
            case 1292: return "TRUNCATED_WRONG_VALUE"
            case 1293: return "TOO_MUCH_AUTO_TIMESTAMP_COLS"
            case 1294: return "INVALID_ON_UPDATE"
            case 1295: return "UNSUPPORTED_PS"
            case 1296: return "GET_ERRMSG"
            case 1297: return "GET_TEMPORARY_ERRMSG"
            case 1298: return "UNKNOWN_TIME_ZONE"
            case 1299: return "WARN_INVALID_TIMESTAMP"
            case 1300: return "INVALID_CHARACTER_STRING"
            case 1301: return "WARN_ALLOWED_PACKET_OVERFLOWED"
            case 1302: return "CONFLICTING_DECLARATIONS"
            case 1303: return "SP_NO_RECURSIVE_CREATE"
            case 1304: return "SP_ALREADY_EXISTS"
            case 1305: return "SP_DOES_NOT_EXIST"
            case 1306: return "SP_DROP_FAILED"
            case 1307: return "SP_STORE_FAILED"
            case 1308: return "SP_LILABEL_MISMATCH"
            case 1309: return "SP_LABEL_REDEFINE"
            case 1310: return "SP_LABEL_MISMATCH"
            case 1311: return "SP_UNINIT_VAR"
            case 1312: return "SP_BADSELECT"
            case 1313: return "SP_BADRETURN"
            case 1314: return "SP_BADSTATEMENT"
            case 1315: return "UPDATE_LOG_DEPRECATED_IGNORED"
            case 1316: return "UPDATE_LOG_DEPRECATED_TRANSLATED"
            case 1317: return "QUERY_INTERRUPTED"
            case 1318: return "SP_WRONG_NO_OF_ARGS"
            case 1319: return "SP_COND_MISMATCH"
            case 1320: return "SP_NORETURN"
            case 1321: return "SP_NORETURNEND"
            case 1322: return "SP_BAD_CURSOR_QUERY"
            case 1323: return "SP_BAD_CURSOR_SELECT"
            case 1324: return "SP_CURSOR_MISMATCH"
            case 1325: return "SP_CURSOR_ALREADY_OPEN"
            case 1326: return "SP_CURSOR_NOT_OPEN"
            case 1327: return "SP_UNDECLARED_VAR"
            case 1328: return "SP_WRONG_NO_OF_FETCH_ARGS"
            case 1329: return "SP_FETCH_NO_DATA"
            case 1330: return "SP_DUP_PARAM"
            case 1331: return "SP_DUP_VAR"
            case 1332: return "SP_DUP_COND"
            case 1333: return "SP_DUP_CURS"
            case 1334: return "SP_CANT_ALTER"
            case 1335: return "SP_SUBSELECT_NYI"
            case 1336: return "STMT_NOT_ALLOWED_IN_SF_OR_TRG"
            case 1337: return "SP_VARCOND_AFTER_CURSHNDLR"
            case 1338: return "SP_CURSOR_AFTER_HANDLER"
            case 1339: return "_FOUND"
            case 1340: return "FPARSER_TOO_BIG_FILE"
            case 1341: return "FPARSER_BAD_HEADER"
            case 1342: return "FPARSER_EOF_IN_COMMENT"
            case 1343: return "FPARSER_ERROR_IN_PARAMETER"
            case 1344: return "FPARSER_EOF_IN_UNKNOWN_PARAMETER"
            case 1345: return "VIEW_NO_EXPLAIN"
            case 1346: return "FRM_UNKNOWN_TYPE"
            case 1347: return "WRONG_OBJECT"
            case 1348: return "NONUPDATEABLE_COLUMN"
            case 1349: return "VIEW_SELECT_DERIVED_UNUSED"
            case 1350: return "VIEW_SELECT_CLAUSE"
            case 1351: return "VIEW_SELECT_VARIABLE"
            case 1352: return "VIEW_SELECT_TMPTABLE"
            case 1353: return "VIEW_WRONG_LIST"
            case 1354: return "WARN_VIEW_MERGE"
            case 1355: return "WARN_VIEW_WITHOUT_KEY"
            case 1356: return "VIEW_INVALID"
            case 1357: return "SP_NO_DROP_SP"
            case 1358: return "SP_GOTO_IN_HNDLR"
            case 1359: return "TRG_ALREADY_EXISTS"
            case 1360: return "TRG_DOES_NOT_EXIST"
            case 1361: return "TRG_ON_VIEW_OR_TEMP_TABLE"
            case 1362: return "TRG_CANT_CHANGE_ROW"
            case 1363: return "TRG_NO_SUCH_ROW_IN_TRG"
            case 1364: return "NO_DEFAULT_FOR_FIELD"
            case 1365: return "DIVISION_BY_ZERO"
            case 1366: return "TRUNCATED_WRONG_VALUE_FOR_FIELD"
            case 1367: return "ILLEGAL_VALUE_FOR_TYPE"
            case 1368: return "VIEW_NONUPD_CHECK"
            case 1369: return "VIEW_CHECK_FAILED"
            case 1370: return "PROCACCESS_DENIED_ERROR"
            case 1371: return "RELAY_LOG_FAIL"
            case 1372: return "PASSWD_LENGTH"
            case 1373: return "UNKNOWN_TARGET_BINLOG"
            case 1374: return "IO_ERR_LOG_INDEX_READ"
            case 1375: return "BINLOG_PURGE_PROHIBITED"
            case 1376: return "FSEEK_FAIL"
            case 1377: return "BINLOG_PURGE_FATAL_ERR"
            case 1378: return "LOG_IN_USE"
            case 1379: return "LOG_PURGE_UNKNOWN_ERR"
            case 1380: return "RELAY_LOG_INIT"
            case 1381: return "NO_BINARY_LOGGING"
            case 1382: return "RESERVED_SYNTAX"
            case 1383: return "WSAS_FAILED"
            case 1384: return "DIFF_GROUPS_PROC"
            case 1385: return "NO_GROUP_FOR_PROC"
            case 1386: return "ORDER_WITH_PROC"
            case 1387: return "LOGGING_PROHIBIT_CHANGING_OF"
            case 1388: return "NO_FILE_MAPPING"
            case 1389: return "WRONG_MAGIC"
            case 1390: return "PS_MANY_PARAM"
            case 1391: return "KEY_PART_0: "
            case 1392: return "VIEW_CHECKSUM"
            case 1393: return "VIEW_MULTIUPDATE"
            case 1394: return "VIEW_NO_INSERT_FIELD_LIST"
            case 1395: return "VIEW_DELETE_MERGE_VIEW"
            case 1396: return "CANNOT_USER"
            case 1397: return "XAER_NOTA"
            case 1398: return "XAER_INVAL"
            case 1399: return "XAER_RMFAIL"
            case 1400: return "XAER_OUTSIDE"
            case 1401: return "XAER_RMERR"
            case 1402: return "XA_RBROLLBACK"
            case 1403: return "NONEXISTING_PROC_GRANT"
            case 1404: return "PROC_AUTO_GRANT_FAIL"
            case 1405: return "PROC_AUTO_REVOKE_FAIL"
            case 1406: return "DATA_TOO_LONG"
            case 1407: return "SP_BAD_SQLSTATE"
            case 1408: return "STARTUP"
            case 1409: return "LOAD_FROM_FIXED_SIZE_ROWS_TO_VAR"
            case 1410: return "CANT_CREATE_USER_WITH_GRANT"
            case 1411: return "WRONG_VALUE_FOR_TYPE"
            case 1412: return "TABLE_DEF_CHANGED"
            case 1413: return "SP_DUP_HANDLER"
            case 1414: return "SP_NOT_VAR_ARG"
            case 1415: return "SP_NO_RETSET"
            case 1416: return "CANT_CREATE_GEOMETRY_OBJECT"
            case 1417: return "FAILED_ROUTINE_BREAK_BINLOG"
            case 1418: return "BINLOG_UNSAFE_ROUTINE"
            case 1419: return "BINLOG_CREATE_ROUTINE_NEED_SUPER"
            case 1420: return "EXEC_STMT_WITH_OPEN_CURSOR"
            case 1421: return "STMT_HAS_NO_OPEN_CURSOR"
            case 1422: return "COMMIT_NOT_ALLOWED_IN_SF_OR_TRG"
            case 1423: return "NO_DEFAULT_FOR_VIEW_FIELD"
            case 1424: return "SP_NO_RECURSION"
            case 1425: return "TOO_BIG_SCALE"
            case 1426: return "TOO_BIG_PRECISION"
            case 1427: return "M_BIGGER_THAN_D"
            case 1428: return "WRONG_LOCK_OF_SYSTEM_TABLE"
            case 1429: return "CONNECT_TO_FOREIGN_DATA_SOURCE"
            case 1430: return "QUERY_ON_FOREIGN_DATA_SOURCE"
            case 1431: return "FOREIGN_DATA_SOURCE_DOESNT_EXIST"
            case 1432: return "FOREIGN_DATA_STRING_INVALID_CANT_CREATE"
            case 1433: return "FOREIGN_DATA_STRING_INVALID"
            case 1434: return "CANT_CREATE_FEDERATED_TABLE"
            case 1435: return "TRG_IN_WRONG_SCHEMA"
            case 1436: return "STACK_OVERRUN_NEED_MORE"
            case 1437: return "TOO_LONG_BODY"
            case 1438: return "WARN_CANT_DROP_DEFAULT_KEYCACHE"
            case 1439: return "TOO_BIG_DISPLAYWIDTH"
            case 1440: return "XAER_DUPID"
            case 1441: return "DATETIME_FUNCTION_OVERFLOW"
            case 1442: return "CANT_UPDATE_USED_TABLE_IN_SF_OR_TRG"
            case 1443: return "VIEW_PREVENT_UPDATE"
            case 1444: return "PS_NO_RECURSION"
            case 1445: return "SP_CANT_SET_AUTOCOMMIT"
            case 1446: return "MALFORMED_DEFINER"
            case 1447: return "VIEW_FRM_NO_USER"
            case 1448: return "VIEW_OTHER_USER"
            case 1449: return "NO_SUCH_USER"
            case 1450: return "FORBID_SCHEMA_CHANGE"
            case 1451: return "ROW_IS_REFERENCED_2: "
            case 1452: return "NO_REFERENCED_ROW_2: "
            case 1453: return "SP_BAD_VAR_SHADOW"
            case 1454: return "TRG_NO_DEFINER"
            case 1455: return "OLD_FILE_FORMAT"
            case 1456: return "SP_RECURSION_LIMIT"
            case 1457: return "SP_PROC_TABLE_CORRUPT"
            case 1458: return "SP_WRONG_NAME"
            case 1459: return "TABLE_NEEDS_UPGRADE"
            case 1460: return "SP_NO_AGGREGATE"
            case 1461: return "MAX_PREPARED_STMT_COUNT_REACHED"
            case 1462: return "VIEW_RECURSIVE"
            case 1463: return "NON_GROUPING_FIELD_USED"
            case 1464: return "TABLE_CANT_HANDLE_SPKEYS"
            case 1465: return "NO_TRIGGERS_ON_SYSTEM_SCHEMA"
            case 1466: return "REMOVED_SPACES"
            case 1467: return "AUTOINC_READ_FAILED"
            case 1468: return "USERNAME"
            case 1469: return "HOSTNAME"
            case 1470: return "WRONG_STRING_LENGTH"
            case 1471: return "NON_INSERTABLE_TABLE"
            case 1472: return "ADMIN_WRONG_MRG_TABLE"
            case 1473: return "TOO_HIGH_LEVEL_OF_NESTING_FOR_SELECT"
            case 1474: return "NAME_BECOMES_EMPTY"
            case 1475: return "AMBIGUOUS_FIELD_TERM"
            case 1476: return "FOREIGN_SERVER_EXISTS"
            case 1477: return "FOREIGN_SERVER_DOESNT_EXIST"
            case 1478: return "ILLEGAL_HA_CREATE_OPTION"
            case 1479: return "PARTITION_REQUIRES_VALUES_ERROR"
            case 1480: return "PARTITION_WRONG_VALUES_ERROR"
            case 1481: return "PARTITION_MAXVALUE_ERROR"
            case 1482: return "PARTITION_SUBPARTITION_ERROR"
            case 1483: return "PARTITION_SUBPART_MIX_ERROR"
            case 1484: return "PARTITION_WRONG_NO_PART_ERROR"
            case 1485: return "PARTITION_WRONG_NO_SUBPART_ERROR"
            case 1486: return "WRONG_EXPR_IN_PARTITION_FUNC_ERROR"
            case 1487: return "NO_CONST_EXPR_IN_RANGE_OR_LIST_ERROR"
            case 1488: return "FIELD_NOT_FOUND_PART_ERROR"
            case 1489: return "LIST_OF_FIELDS_ONLY_IN_HASH_ERROR"
            case 1490: return "INCONSISTENT_PARTITION_INFO_ERROR"
            case 1491: return "PARTITION_FUNC_NOT_ALLOWED_ERROR"
            case 1492: return "PARTITIONS_MUST_BE_DEFINED_ERROR"
            case 1493: return "RANGE_NOT_INCREASING_ERROR"
            case 1494: return "INCONSISTENT_TYPE_OF_FUNCTIONS_ERROR"
            case 1495: return "MULTIPLE_DEF_CONST_IN_LIST_PART_ERROR"
            case 1496: return "PARTITION_ENTRY_ERROR"
            case 1497: return "MIX_HANDLER_ERROR"
            case 1498: return "PARTITION_NOT_DEFINED_ERROR"
            case 1499: return "TOO_MANY_PARTITIONS_ERROR"
            case 1500: return "SUBPARTITION_ERROR"
            case 1501: return "CANT_CREATE_HANDLER_FILE"
            case 1502: return "BLOB_FIELD_IN_PART_FUNC_ERROR"
            case 1503: return "UNIQUE_KEY_NEED_ALL_FIELDS_IN_PF"
            case 1504: return "NO_PARTS_ERROR"
            case 1505: return "PARTITION_MGMT_ON_NONPARTITIONED"
            case 1506: return "FOREIGN_KEY_ON_PARTITIONED"
            case 1507: return "DROP_PARTITION_NON_EXISTENT"
            case 1508: return "DROP_LAST_PARTITION"
            case 1509: return "COALESCE_ONLY_ON_HASH_PARTITION"
            case 1510: return "REORG_HASH_ONLY_ON_SAME_NO"
            case 1511: return "REORG_NO_PARAM_ERROR"
            case 1512: return "ONLY_ON_RANGE_LIST_PARTITION"
            case 1513: return "ADD_PARTITION_SUBPART_ERROR"
            case 1514: return "ADD_PARTITION_NO_NEW_PARTITION"
            case 1515: return "COALESCE_PARTITION_NO_PARTITION"
            case 1516: return "REORG_PARTITION_NOT_EXIST"
            case 1517: return "SAME_NAME_PARTITION"
            case 1518: return "NO_BINLOG_ERROR"
            case 1519: return "CONSECUTIVE_REORG_PARTITIONS"
            case 1520: return "REORG_OUTSIDE_RANGE"
            case 1521: return "PARTITION_FUNCTION_FAILURE"
            case 1522: return "PART_STATE_ERROR"
            case 1523: return "LIMITED_PART_RANGE"
            case 1524: return "PLUGIN_IS_NOT_LOADED"
            case 1525: return "WRONG_VALUE"
            case 1526: return "NO_PARTITION_FOR_GIVEN_VALUE"
            case 1527: return "FILEGROUP_OPTION_ONLY_ONCE"
            case 1528: return "CREATE_FILEGROUP_FAILED"
            case 1529: return "DROP_FILEGROUP_FAILED"
            case 1530: return "TABLESPACE_AUTO_EXTEND_ERROR"
            case 1531: return "WRONG_SIZE_NUMBER"
            case 1532: return "SIZE_OVERFLOW_ERROR"
            case 1533: return "ALTER_FILEGROUP_FAILED"
            case 1534: return "BINLOG_ROW_LOGGING_FAILED"
            case 1535: return "BINLOG_ROW_WRONG_TABLE_DEF"
            case 1536: return "BINLOG_ROW_RBR_TO_SBR"
            case 1537: return "EVENT_ALREADY_EXISTS"
            case 1538: return "EVENT_STORE_FAILED"
            case 1539: return "EVENT_DOES_NOT_EXIST"
            case 1540: return "EVENT_CANT_ALTER"
            case 1541: return "EVENT_DROP_FAILED"
            case 1542: return "EVENT_INTERVAL_NOT_POSITIVE_OR_TOO_BIG"
            case 1543: return "EVENT_ENDS_BEFORE_STARTS"
            case 1544: return "EVENT_EXEC_TIME_IN_THE_PAST"
            case 1545: return "EVENT_OPEN_TABLE_FAILED"
            case 1546: return "EVENT_NEITHER_M_EXPR_NOR_M_AT"
            case 1547: return "OBSOLETE_COL_COUNT_DOESNT_MATCH_CORRUPTED"
            case 1548: return "OBSOLETE_CANNOT_LOAD_FROM_TABLE"
            case 1549: return "EVENT_CANNOT_DELETE"
            case 1550: return "EVENT_COMPILE_ERROR"
            case 1551: return "EVENT_SAME_NAME"
            case 1552: return "EVENT_DATA_TOO_LONG"
            case 1553: return "DROP_INDEX_FK"
            case 1554: return "WARN_DEPRECATED_SYNTAX_WITH_VER"
            case 1555: return "CANT_WRITE_LOCK_LOG_TABLE"
            case 1556: return "CANT_LOCK_LOG_TABLE"
            case 1557: return "FOREIGN_DUPLICATE_KEY_OLD_UNUSED"
            case 1558: return "COL_COUNT_DOESNT_MATCH_PLEASE_UPDATE"
            case 1559: return "TEMP_TABLE_PREVENTS_SWITCH_OUT_OF_RBR"
            case 1560: return "STORED_FUNCTION_PREVENTS_SWITCH_BINLOG_FORMAT"
            case 1561: return "NDB_CANT_SWITCH_BINLOG_FORMAT"
            case 1562: return "PARTITION_NO_TEMPORARY"
            case 1563: return "PARTITION_CONST_DOMAIN_ERROR"
            case 1564: return "PARTITION_FUNCTION_IS_NOT_ALLOWED"
            case 1565: return "DDL_LOG_ERROR"
            case 1566: return "NULL_IN_VALUES_LESS_THAN"
            case 1567: return "WRONG_PARTITION_NAME"
            case 1568: return "CANT_CHANGE_TX_CHARACTERISTICS"
            case 1569: return "_ENTRY_AUTOINCREMENT_CASE"
            case 1570: return "EVENT_MODIFY_QUEUE_ERROR"
            case 1571: return "EVENT_SET_VAR_ERROR"
            case 1572: return "PARTITION_MERGE_ERROR"
            case 1573: return "CANT_ACTIVATE_LOG"
            case 1574: return "RBR_NOT_AVAILABLE"
            case 1575: return "BASE64_DECODE_ERROR"
            case 1576: return "EVENT_RECURSION_FORBIDDEN"
            case 1577: return "EVENTS_DB_ERROR"
            case 1578: return "ONLY_INTEGERS_ALLOWED"
            case 1579: return "UNSUPORTED_LOG_ENGINE"
            case 1580: return "BAD_LOG_STATEMENT"
            case 1581: return "CANT_RENAME_LOG_TABLE"
            case 1582: return "WRONG_PARAMCOUNT_TO_NATIVE_FCT"
            case 1583: return "WRONG_PARAMETERS_TO_NATIVE_FCT"
            case 1584: return "WRONG_PARAMETERS_TO_STORED_FCT"
            case 1585: return "NATIVE_FCT_NAME_COLLISION"
            case 1586: return "DUP_ENTRY_WITH_KEY_NAME"
            case 1587: return "BINLOG_PURGE_EMFILE"
            case 1588: return "EVENT_CANNOT_CREATE_IN_THE_PAST"
            case 1589: return "EVENT_CANNOT_ALTER_IN_THE_PAST"
            case 1590: return "SLAVE_INCIDENT"
            case 1591: return "NO_PARTITION_FOR_GIVEN_VALUE_SILENT"
            case 1592: return "BINLOG_UNSAFE_STATEMENT"
            case 1593: return "SLAVE_FATAL_ERROR"
            case 1594: return "SLAVE_RELAY_LOG_READ_FAILURE"
            case 1595: return "SLAVE_RELAY_LOG_WRITE_FAILURE"
            case 1596: return "SLAVE_CREATE_EVENT_FAILURE"
            case 1597: return "SLAVE_MASTER_COM_FAILURE"
            case 1598: return "BINLOG_LOGGING_IMPOSSIBLE"
            case 1599: return "VIEW_NO_CREATION_CTX"
            case 1600: return "VIEW_INVALID_CREATION_CTX"
            case 1601: return "SR_INVALID_CREATION_CTX"
            case 1602: return "TRG_CORRUPTED_FILE"
            case 1603: return "TRG_NO_CREATION_CTX"
            case 1604: return "TRG_INVALID_CREATION_CTX"
            case 1605: return "EVENT_INVALID_CREATION_CTX"
            case 1606: return "TRG_CANT_OPEN_TABLE"
            case 1607: return "CANT_CREATE_SROUTINE"
            case 1608: return "NEVER_USED"
            case 1609: return "NO_FORMAT_DESCRIPTION_EVENT_BEFORE_BINLOG_STATEMENT"
            case 1610: return "SLAVE_CORRUPT_EVENT"
            case 1611: return "LOAD_DATA_INVALID_COLUMN_UNUSED"
            case 1612: return "LOG_PURGE_NO_FILE"
            case 1613: return "XA_RBTIMEOUT"
            case 1614: return "XA_RBDEADLOCK"
            case 1615: return "NEED_REPREPARE"
            case 1616: return "DELAYED_NOT_SUPPORTED"
            case 1617: return "N_NO_MASTER_INFO"
            case 1618: return "N_OPTION_IGNORED"
            case 1619: return "PLUGIN_DELETE_BUILTIN"
            case 1620: return "N_PLUGIN_BUSY"
            case 1621: return "VARIABLE_IS_READONLY"
            case 1622: return "WARN_ENGINE_TRANSACTION_ROLLBACK"
            case 1623: return "SLAVE_HEARTBEAT_FAILURE"
            case 1624: return "SLAVE_HEARTBEAT_VALUE_OUT_OF_RANGE"
            case 1625: return "NDB_REPLICATION_SCHEMA_ERROR"
            case 1626: return "CONFLICT_FN_PARSE_ERROR"
            case 1627: return "EXCEPTIONS_WRITE_ERROR"
            case 1628: return "TOO_LONG_TABLE_COMMENT"
            case 1629: return "TOO_LONG_FIELD_COMMENT"
            case 1630: return "FUNC_INEXISTENT_NAME_COLLISION"
            case 1631: return "DATABASE_NAME"
            case 1632: return "TABLE_NAME"
            case 1633: return "PARTITION_NAME"
            case 1634: return "SUBPARTITION_NAME"
            case 1635: return "TEMPORARY_NAME"
            case 1636: return "RENAMED_NAME"
            case 1637: return "TOO_MANY_CONCURRENT_TRXS"
            case 1638: return "N_NON_ASCII_SEPARATOR_NOT_IMPLEMENTED"
            case 1639: return "DEBUG_SYNC_TIMEOUT"
            case 1640: return "DEBUG_SYNC_HIT_LIMIT"
            case 1641: return "DUP_SIGNAL_SET"
            case 1642: return "SIGNAL_WARN"
            case 1643: return "SIGNAL_NOT_FOUND"
            case 1644: return "SIGNAL_EXCEPTION"
            case 1645: return "RESIGNAL_WITHOUT_ACTIVE_HANDLER"
            case 1646: return "SIGNAL_BAD_CONDITION_TYPE"
            case 1647: return "N_COND_ITEM_TRUNCATED"
            case 1648: return "COND_ITEM_TOO_LONG"
            case 1649: return "UNKNOWN_LOCALE"
            case 1650: return "SLAVE_IGNORE_SERVER_IDS"
            case 1651: return "QUERY_CACHE_DISABLED"
            case 1652: return "SAME_NAME_PARTITION_FIELD"
            case 1653: return "PARTITION_COLUMN_LIST_ERROR"
            case 1654: return "WRONG_TYPE_COLUMN_VALUE_ERROR"
            case 1655: return "TOO_MANY_PARTITION_FUNC_FIELDS_ERROR"
            case 1656: return "MAXVALUE_IN_VALUES_IN"
            case 1657: return "TOO_MANY_VALUES_ERROR"
            case 1658: return "ROW_SINGLE_PARTITION_FIELD_ERROR"
            case 1659: return "FIELD_TYPE_NOT_ALLOWED_AS_PARTITION_FIELD"
            case 1660: return "PARTITION_FIELDS_TOO_LONG"
            case 1661: return "BINLOG_ROW_ENGINE_AND_STMT_ENGINE"
            case 1662: return "BINLOG_ROW_MODE_AND_STMT_ENGINE"
            case 1663: return "BINLOG_UNSAFE_AND_STMT_ENGINE"
            case 1664: return "BINLOG_ROW_INJECTION_AND_STMT_ENGINE"
            case 1665: return "BINLOG_STMT_MODE_AND_ROW_ENGINE"
            case 1666: return "BINLOG_ROW_INJECTION_AND_STMT_MODE"
            case 1667: return "BINLOG_MULTIPLE_ENGINES_AND_SELF_LOGGING_ENGINE"
            case 1668: return "BINLOG_UNSAFE_LIMIT"
            case 1669: return "UNUSED4: "
            case 1670: return "BINLOG_UNSAFE_SYSTEM_TABLE"
            case 1671: return "BINLOG_UNSAFE_AUTOINC_COLUMNS"
            case 1672: return "BINLOG_UNSAFE_UDF"
            case 1673: return "BINLOG_UNSAFE_SYSTEM_VARIABLE"
            case 1674: return "BINLOG_UNSAFE_SYSTEM_FUNCTION"
            case 1675: return "BINLOG_UNSAFE_NONTRANS_AFTER_TRANS"
            case 1676: return "MESSAGE_AND_STATEMENT"
            case 1677: return "SLAVE_CONVERSION_FAILED"
            case 1678: return "SLAVE_CANT_CREATE_CONVERSION"
            case 1679: return "INSIDE_TRANSACTION_PREVENTS_SWITCH_BINLOG_FORMAT"
            case 1680: return "PATH_LENGTH"
            case 1681: return "WARN_DEPRECATED_SYNTAX_NO_REPLACEMENT"
            case 1682: return "WRONG_NATIVE_TABLE_STRUCTURE"
            case 1683: return "WRONG_PERFSCHEMA_USAGE"
            case 1684: return "WARN_I_S_SKIPPED_TABLE"
            case 1685: return "INSIDE_TRANSACTION_PREVENTS_SWITCH_BINLOG_DIRECT"
            case 1686: return "STORED_FUNCTION_PREVENTS_SWITCH_BINLOG_DIRECT"
            case 1687: return "SPATIAL_MUST_HAVE_GEOM_COL"
            case 1688: return "TOO_LONG_INDEX_COMMENT"
            case 1689: return "LOCK_ABORTED"
            case 1690: return "DATA_OUT_OF_RANGE"
            case 1691: return "WRONG_SPVAR_TYPE_IN_LIMIT"
            case 1692: return "BINLOG_UNSAFE_MULTIPLE_ENGINES_AND_SELF_LOGGING_ENGINE"
            case 1693: return "BINLOG_UNSAFE_MIXED_STATEMENT"
            case 1694: return "INSIDE_TRANSACTION_PREVENTS_SWITCH_SQL_LOG_BIN"
            case 1695: return "STORED_FUNCTION_PREVENTS_SWITCH_SQL_LOG_BIN"
            case 1696: return "FAILED_READ_FROM_PAR_FILE"
            case 1697: return "VALUES_IS_NOT_INT_TYPE_ERROR"
            case 1698: return "ACCESS_DENIED_NO_PASSWORD_ERROR"
            case 1699: return "SET_PASSWORD_AUTH_PLUGIN"
            case 1700: return "GRANT_PLUGIN_USER_EXISTS"
            case 1701: return "TRUNCATE_ILLEGAL_FK"
            case 1702: return "PLUGIN_IS_PERMANENT"
            case 1703: return "SLAVE_HEARTBEAT_VALUE_OUT_OF_RANGE_MIN"
            case 1704: return "SLAVE_HEARTBEAT_VALUE_OUT_OF_RANGE_MAX"
            case 1705: return "STMT_CACHE_FULL"
            case 1706: return "MULTI_UPDATE_KEY_CONFLICT"
            case 1707: return "TABLE_NEEDS_REBUILD"
            case 1708: return "N_OPTION_BELOW_LIMIT"
            case 1709: return "INDEX_COLUMN_TOO_LONG"
            case 1710: return "ERROR_IN_TRIGGER_BODY"
            case 1711: return "ERROR_IN_UNKNOWN_TRIGGER_BODY"
            case 1712: return "INDEX_CORRUPT"
            case 1713: return "UNDO_RECORD_TOO_BIG"
            case 1714: return "BINLOG_UNSAFE_INSERT_IGNORE_SELECT"
            case 1715: return "BINLOG_UNSAFE_INSERT_SELECT_UPDATE"
            case 1716: return "BINLOG_UNSAFE_REPLACE_SELECT"
            case 1717: return "BINLOG_UNSAFE_CREATE_IGNORE_SELECT"
            case 1718: return "BINLOG_UNSAFE_CREATE_REPLACE_SELECT"
            case 1719: return "BINLOG_UNSAFE_UPDATE_IGNORE"
            case 1720: return "PLUGIN_NO_UNINSTALL"
            case 1721: return "PLUGIN_NO_INSTALL"
            case 1722: return "BINLOG_UNSAFE_WRITE_AUTOINC_SELECT"
            case 1723: return "BINLOG_UNSAFE_CREATE_SELECT_AUTOINC"
            case 1724: return "BINLOG_UNSAFE_INSERT_TWO_KEYS"
            case 1725: return "TABLE_IN_FK_CHECK"
            case 1726: return "UNSUPPORTED_ENGINE"
            case 1727: return "BINLOG_UNSAFE_AUTOINC_NOT_FIRST"
            case 1728: return "CANNOT_LOAD_FROM_TABLE_V2: "
            case 1729: return "MASTER_DELAY_VALUE_OUT_OF_RANGE"
            case 1730: return "ONLY_FD_AND_RBR_EVENTS_ALLOWED_IN_BINLOG_STATEMENT"
            case 1731: return "PARTITION_EXCHANGE_DIFFERENT_OPTION"
            case 1732: return "PARTITION_EXCHANGE_PART_TABLE"
            case 1733: return "PARTITION_EXCHANGE_TEMP_TABLE"
            case 1734: return "PARTITION_INSTEAD_OF_SUBPARTITION"
            case 1735: return "UNKNOWN_PARTITION"
            case 1736: return "TABLES_DIFFERENT_METADATA"
            case 1737: return "ROW_DOES_NOT_MATCH_PARTITION"
            case 1738: return "BINLOG_CACHE_SIZE_GREATER_THAN_MAX"
            case 1739: return "WARN_INDEX_NOT_APPLICABLE"
            case 1740: return "PARTITION_EXCHANGE_FOREIGN_KEY"
            case 1741: return "NO_SUCH_KEY_VALUE"
            case 1742: return "RPL_INFO_DATA_TOO_LONG"
            case 1743: return "NETWORK_READ_EVENT_CHECKSUM_FAILURE"
            case 1744: return "BINLOG_READ_EVENT_CHECKSUM_FAILURE"
            case 1745: return "BINLOG_STMT_CACHE_SIZE_GREATER_THAN_MAX"
            case 1746: return "CANT_UPDATE_TABLE_IN_CREATE_TABLE_SELECT"
            case 1747: return "PARTITION_CLAUSE_ON_NONPARTITIONED"
            case 1748: return "ROW_DOES_NOT_MATCH_GIVEN_PARTITION_SET"
            case 1749: return "NO_SUCH_PARTITION__UNUSED"
            case 1750: return "CHANGE_RPL_INFO_REPOSITORY_FAILURE"
            case 1751: return "WARNING_NOT_COMPLETE_ROLLBACK_WITH_CREATED_TEMP_TABLE"
            case 1752: return "WARNING_NOT_COMPLETE_ROLLBACK_WITH_DROPPED_TEMP_TABLE"
            case 1753: return "MTS_FEATURE_IS_NOT_SUPPORTED"
            case 1754: return "MTS_UPDATED_DBS_GREATER_MAX"
            case 1755: return "MTS_CANT_PARALLEL"
            case 1756: return "MTS_INCONSISTENT_DATA"
            case 1757: return "FULLTEXT_NOT_SUPPORTED_WITH_PARTITIONING"
            case 1758: return "DA_INVALID_CONDITION_NUMBER"
            case 1759: return "INSECURE_PLAIN_TEXT"
            case 1760: return "INSECURE_CHANGE_MASTER"
            case 1761: return "FOREIGN_DUPLICATE_KEY_WITH_CHILD_INFO"
            case 1762: return "FOREIGN_DUPLICATE_KEY_WITHOUT_CHILD_INFO"
            case 1763: return "SQLTHREAD_WITH_SECURE_SLAVE"
            case 1764: return "TABLE_HAS_NO_FT"
            case 1765: return "VARIABLE_NOT_SETTABLE_IN_SF_OR_TRIGGER"
            case 1766: return "VARIABLE_NOT_SETTABLE_IN_TRANSACTION"
            case 1767: return "GTID_NEXT_IS_NOT_IN_GTID_NEXT_LIST"
            case 1768: return "CANT_CHANGE_GTID_NEXT_IN_TRANSACTION"
            case 1769: return "SET_STATEMENT_CANNOT_INVOKE_FUNCTION"
            case 1770: return "GTID_NEXT_CANT_BE_AUTOMATIC_IF_GTID_NEXT_LIST_IS_NON_NULL"
            case 1771: return "SKIPPING_LOGGED_TRANSACTION"
            case 1772: return "MALFORMED_GTID_SET_SPECIFICATION"
            case 1773: return "MALFORMED_GTID_SET_ENCODING"
            case 1774: return "MALFORMED_GTID_SPECIFICATION"
            case 1775: return "GNO_EXHAUSTED"
            case 1776: return "BAD_SLAVE_AUTO_POSITION"
            case 1777: return "AUTO_POSITION_REQUIRES_GTID_MODE_NOT_OFF"
            case 1778: return "CANT_DO_IMPLICIT_COMMIT_IN_TRX_WHEN_GTID_NEXT_IS_SET"
            case 1779: return "GTID_MODE_ON_REQUIRES_ENFORCE_GTID_CONSISTENCY_ON"
            case 1780: return "GTID_MODE_REQUIRES_BINLOG"
            case 1781: return "CANT_SET_GTID_NEXT_TO_GTID_WHEN_GTID_MODE_IS_OFF"
            case 1782: return "CANT_SET_GTID_NEXT_TO_ANONYMOUS_WHEN_GTID_MODE_IS_ON"
            case 1783: return "CANT_SET_GTID_NEXT_LIST_TO_NON_NULL_WHEN_GTID_MODE_IS_OFF"
            case 1784: return "FOUND_GTID_EVENT_WHEN_GTID_MODE_IS_OFF__UNUSED"
            case 1785: return "GTID_UNSAFE_NON_TRANSACTIONAL_TABLE"
            case 1786: return "GTID_UNSAFE_CREATE_SELECT"
            case 1787: return "GTID_UNSAFE_CREATE_DROP_TEMPORARY_TABLE_IN_TRANSACTION"
            case 1788: return "GTID_MODE_CAN_ONLY_CHANGE_ONE_STEP_AT_A_TIME"
            case 1789: return "MASTER_HAS_PURGED_REQUIRED_GTIDS"
            case 1790: return "CANT_SET_GTID_NEXT_WHEN_OWNING_GTID"
            case 1791: return "UNKNOWN_EXPLAIN_FORMAT"
            case 1792: return "CANT_EXECUTE_IN_READ_ONLY_TRANSACTION"
            case 1793: return "TOO_LONG_TABLE_PARTITION_COMMENT"
            case 1794: return "SLAVE_CONFIGURATION"
            case 1795: return "INNODB_FT_LIMIT"
            case 1796: return "INNODB_NO_FT_TEMP_TABLE"
            case 1797: return "INNODB_FT_WRONG_DOCID_COLUMN"
            case 1798: return "INNODB_FT_WRONG_DOCID_INDEX"
            case 1799: return "INNODB_ONLINE_LOG_TOO_BIG"
            case 1800: return "UNKNOWN_ALTER_ALGORITHM"
            case 1801: return "UNKNOWN_ALTER_LOCK"
            case 1802: return "MTS_CHANGE_MASTER_CANT_RUN_WITH_GAPS"
            case 1803: return "MTS_RECOVERY_FAILURE"
            case 1804: return "MTS_RESET_WORKERS"
            case 1805: return "COL_COUNT_DOESNT_MATCH_CORRUPTED_V2: "
            case 1806: return "SLAVE_SILENT_RETRY_TRANSACTION"
            case 1807: return "DISCARD_FK_CHECKS_RUNNING"
            case 1808: return "TABLE_SCHEMA_MISMATCH"
            case 1809: return "TABLE_IN_SYSTEM_TABLESPACE"
            case 1810: return "IO_READ_ERROR"
            case 1811: return "IO_WRITE_ERROR"
            case 1812: return "TABLESPACE_MISSING"
            case 1813: return "TABLESPACE_EXISTS"
            case 1814: return "TABLESPACE_DISCARDED"
            case 1815: return "INTERNAL_ERROR"
            case 1816: return "INNODB_IMPORT_ERROR"
            case 1817: return "INNODB_INDEX_CORRUPT"
            case 1818: return "INVALID_YEAR_COLUMN_LENGTH"
            case 1819: return "NOT_VALID_PASSWORD"
            case 1820: return "MUST_CHANGE_PASSWORD"
            case 1821: return "FK_NO_INDEX_CHILD"
            case 1822: return "FK_NO_INDEX_PARENT"
            case 1823: return "FK_FAIL_ADD_SYSTEM"
            case 1824: return "FK_CANNOT_OPEN_PARENT"
            case 1825: return "FK_INCORRECT_OPTION"
            case 1826: return "FK_DUP_NAME"
            case 1827: return "PASSWORD_FORMAT"
            case 1828: return "FK_COLUMN_CANNOT_DROP"
            case 1829: return "FK_COLUMN_CANNOT_DROP_CHILD"
            case 1830: return "FK_COLUMN_NOT_NULL"
            case 1831: return "DUP_INDEX"
            case 1832: return "FK_COLUMN_CANNOT_CHANGE"
            case 1833: return "FK_COLUMN_CANNOT_CHANGE_CHILD"
            case 1834: return "UNUSED5: "
            case 1835: return "MALFORMED_PACKET"
            case 1836: return "READ_ONLY_MODE"
            case 1837: return "GTID_NEXT_TYPE_UNDEFINED_GROUP"
            case 1838: return "VARIABLE_NOT_SETTABLE_IN_SP"
            case 1839: return "CANT_SET_GTID_PURGED_WHEN_GTID_MODE_IS_OFF"
            case 1840: return "CANT_SET_GTID_PURGED_WHEN_GTID_EXECUTED_IS_NOT_EMPTY"
            case 1841: return "CANT_SET_GTID_PURGED_WHEN_OWNED_GTIDS_IS_NOT_EMPTY"
            case 1842: return "GTID_PURGED_WAS_CHANGED"
            case 1843: return "GTID_EXECUTED_WAS_CHANGED"
            case 1844: return "BINLOG_STMT_MODE_AND_NO_REPL_TABLES"
            case 1845: return "ALTER_OPERATION_NOT_SUPPORTED"
            case 1846: return "ALTER_OPERATION_NOT_SUPPORTED_REASON"
            case 1847: return "ALTER_OPERATION_NOT_SUPPORTED_REASON_COPY"
            case 1848: return "ALTER_OPERATION_NOT_SUPPORTED_REASON_PARTITION"
            case 1849: return "ALTER_OPERATION_NOT_SUPPORTED_REASON_FK_RENAME"
            case 1850: return "ALTER_OPERATION_NOT_SUPPORTED_REASON_COLUMN_TYPE"
            case 1851: return "ALTER_OPERATION_NOT_SUPPORTED_REASON_FK_CHECK"
            case 1852: return "UNUSED6: "
            case 1853: return "ALTER_OPERATION_NOT_SUPPORTED_REASON_NOPK"
            case 1854: return "ALTER_OPERATION_NOT_SUPPORTED_REASON_AUTOINC"
            case 1855: return "ALTER_OPERATION_NOT_SUPPORTED_REASON_HIDDEN_FTS"
            case 1856: return "ALTER_OPERATION_NOT_SUPPORTED_REASON_CHANGE_FTS"
            case 1857: return "ALTER_OPERATION_NOT_SUPPORTED_REASON_FTS"
            case 1858: return "SQL_SLAVE_SKIP_COUNTER_NOT_SETTABLE_IN_GTID_MODE"
            case 1859: return "DUP_UNKNOWN_IN_INDEX"
            case 1860: return "IDENT_CAUSES_TOO_LONG_PATH"
            case 1861: return "ALTER_OPERATION_NOT_SUPPORTED_REASON_NOT_NULL"
            case 1862: return "MUST_CHANGE_PASSWORD_LOGIN"
            case 1863: return "ROW_IN_WRONG_PARTITION"
            case 1864: return "MTS_EVENT_BIGGER_PENDING_JOBS_SIZE_MAX"
            case 1865: return "INNODB_NO_FT_USES_PARSER"
            case 1866: return "BINLOG_LOGICAL_CORRUPTION"
            case 1867: return "WARN_PURGE_LOG_IN_USE"
            case 1868: return "WARN_PURGE_LOG_IS_ACTIVE"
            case 1869: return "AUTO_INCREMENT_CONFLICT"
            case 1870: return "N_ON_BLOCKHOLE_IN_RBR"
            case 1871: return "SLAVE_MI_INIT_REPOSITORY"
            case 1872: return "SLAVE_RLI_INIT_REPOSITORY"
            case 1873: return "ACCESS_DENIED_CHANGE_USER_ERROR"
            case 1874: return "INNODB_READ_ONLY"
            case 1875: return "STOP_SLAVE_SQL_THREAD_TIMEOUT"
            case 1876: return "STOP_SLAVE_IO_THREAD_TIMEOUT"
            case 1877: return "TABLE_CORRUPT"
            case 1878: return "TEMP_FILE_WRITE_FAILURE"
            case 1879: return "INNODB_FT_AUX_NOT_HEX_ID"
            case 1880: return "OLD_TEMPORALS_UPGRADED"
            case 1881: return "INNODB_FORCED_RECOVERY"
            case 1882: return "AES_INVALID_IV"
            case 1883: return "PLUGIN_CANNOT_BE_UNINSTALLED"
            case 1884: return "GTID_UNSAFE_BINLOG_SPLITTABLE_STATEMENT_AND_GTID_GROUP"
            case 1885: return "SLAVE_HAS_MORE_GTIDS_THAN_MASTER"
            case 2000: return "UNKNOWN_ERROR"
            case 2001: return "SOCKET_CREATE_ERROR"
            case 2002: return "CONNECTION_ERROR"
            case 2003: return "CONN_HOST_ERROR"
            case 2004: return "IPSOCK_ERROR"
            case 2005: return "UNKNOWN_HOST"
            case 2006: return "SERVER_GONE_ERROR"
            case 2007: return "VERSION_ERROR"
            case 2008: return "OUT_OF_MEMORY"
            case 2009: return "WRONG_HOST_INFO"
            case 2010: return "LOCALHOST_CONNECTION"
            case 2011: return "TCP_CONNECTION"
            case 2012: return "SERVER_HANDSHAKE_ERR"
            case 2013: return "SERVER_LOST"
            case 2014: return "COMMANDS_OUT_OF_SYNC"
            case 2015: return "NAMEDPIPE_CONNECTION"
            case 2016: return "NAMEDPIPEWAIT_ERROR"
            case 2017: return "NAMEDPIPEOPEN_ERROR"
            case 2018: return "NAMEDPIPESETSTATE_ERROR"
            case 2019: return "CANT_READ_CHARSET"
            case 2020: return "NET_PACKET_TOO_LARGE"
            case 2021: return "EMBEDDED_CONNECTION"
            case 2022: return "PROBE_SLAVE_STATUS"
            case 2023: return "PROBE_SLAVE_HOSTS"
            case 2024: return "PROBE_SLAVE_CONNECT"
            case 2025: return "PROBE_MASTER_CONNECT"
            case 2026: return "SSL_CONNECTION_ERROR"
            case 2027: return "MALFORMED_PACKET"
            case 2028: return "WRONG_LICENSE"
            case 2029: return "NULL_POINTER"
            case 2030: return "NO_PREPARE_STMT"
            case 2031: return "PARAMS_NOT_BOUND"
            case 2032: return "DATA_TRUNCATED"
            case 2033: return "NO_PARAMETERS_EXISTS"
            case 2034: return "INVALID_PARAMETER_NO"
            case 2035: return "INVALID_BUFFER_USE"
            case 2036: return "UNSUPPORTED_PARAM_TYPE"
            case 2037: return "SHARED_MEMORY_CONNECTION"
            case 2038: return "SHARED_MEMORY_CONNECT_REQUEST_ERROR"
            case 2039: return "SHARED_MEMORY_CONNECT_ANSWER_ERROR"
            case 2040: return "SHARED_MEMORY_CONNECT_FILE_MAP_ERROR"
            case 2041: return "SHARED_MEMORY_CONNECT_MAP_ERROR"
            case 2042: return "SHARED_MEMORY_FILE_MAP_ERROR"
            case 2043: return "SHARED_MEMORY_MAP_ERROR"
            case 2044: return "SHARED_MEMORY_EVENT_ERROR"
            case 2045: return "SHARED_MEMORY_CONNECT_ABANDONED_ERROR"
            case 2046: return "SHARED_MEMORY_CONNECT_SET_ERROR"
            case 2047: return "CONN_UNKNOW_PROTOCOL"
            case 2048: return "INVALID_CONN_HANDLE"
            case 2049: return "SECURE_AUTH"
            case 2050: return "FETCH_CANCELED"
            case 2051: return "NO_DATA"
            case 2052: return "NO_STMT_METADATA"
            case 2053: return "NO_RESULT_SET"
            case 2054: return "NOT_IMPLEMENTED"
            case 2055: return "SERVER_LOST_EXTENDED"
            case 2056: return "STMT_CLOSED"
            case 2057: return "NEW_STMT_METADATA"
            case 2058: return "ALREADY_CONNECTED"
            case 2059: return "AUTH_PLUGIN_CANNOT_LOAD"
            case 2060: return "DUPLICATE_CONNECTION_ATTR"
            case 2061: return "AUTH_PLUGIN_ERR"
            case 2062: return "INSECURE_API_ERR"
            case 3000: return "FILE_CORRUPT"
            case 3001: return "ERROR_ON_MASTER"
            case 3002: return "INCONSISTENT_ERROR"
            case 3003: return "STORAGE_ENGINE_NOT_LOADED"
            case 3004: return "GET_STACKED_DA_WITHOUT_ACTIVE_HANDLER"
            case 3005: return "WARN_LEGACY_SYNTAX_CONVERTED"
            case 3006: return "BINLOG_UNSAFE_FULLTEXT_PLUGIN"
            case 3007: return "CANNOT_DISCARD_TEMPORARY_TABLE"
            case 3008: return "FK_DEPTH_EXCEEDED"
            case 3009: return "COL_COUNT_DOESNT_MATCH_PLEASE_UPDATE_V2: "
            case 3010: return "WARN_TRIGGER_DOESNT_HAVE_CREATED"
            case 3011: return "REFERENCED_TRG_DOES_NOT_EXIST"
            case 3012: return "EXPLAIN_NOT_SUPPORTED"
            case 3013: return "INVALID_FIELD_SIZE"
            case 3014: return "MISSING_HA_CREATE_OPTION"
            case 3015: return "ENGINE_OUT_OF_MEMORY"
            case 3016: return "PASSWORD_EXPIRE_ANONYMOUS_USER"
            case 3017: return "SLAVE_SQL_THREAD_MUST_STOP"
            case 3018: return "NO_FT_MATERIALIZED_SUBQUERY"
            case 3019: return "INNODB_UNDO_LOG_FULL"
            case 3020: return "INVALID_ARGUMENT_FOR_LOGARITHM"
            case 3021: return "SLAVE_CHANNEL_IO_THREAD_MUST_STOP"
            case 3022: return "WARN_OPEN_TEMP_TABLES_MUST_BE_ZERO"
            case 3023: return "WARN_ONLY_MASTER_LOG_FILE_NO_POS"
            case 3024: return "QUERY_TIMEOUT"
            case 3025: return "NON_RO_SELECT_DISABLE_TIMER"
            case 3026: return "DUP_LIST_ENTRY"
            case 3027: return "SQL_MODE_NO_EFFECT"
            case 3028: return "AGGREGATE_ORDER_FOR_UNION"
            case 3029: return "AGGREGATE_ORDER_NON_AGG_QUERY"
            case 3030: return "SLAVE_WORKER_STOPPED_PREVIOUS_THD_ERROR"
            case 3031: return "DONT_SUPPORT_SLAVE_PRESERVE_COMMIT_ORDER"
            case 3032: return "SERVER_OFFLINE_MODE"
            case 3033: return "GIS_DIFFERENT_SRIDS"
            case 3034: return "GIS_UNSUPPORTED_ARGUMENT"
            case 3035: return "GIS_UNKNOWN_ERROR"
            case 3036: return "GIS_UNKNOWN_EXCEPTION"
            case 3037: return "GIS_INVALID_DATA"
            case 3038: return "BOOST_GEOMETRY_EMPTY_INPUT_EXCEPTION"
            case 3039: return "BOOST_GEOMETRY_CENTROID_EXCEPTION"
            case 3040: return "BOOST_GEOMETRY_OVERLAY_INVALID_INPUT_EXCEPTION"
            case 3041: return "BOOST_GEOMETRY_TURN_INFO_EXCEPTION"
            case 3042: return "BOOST_GEOMETRY_SELF_INTERSECTION_POINT_EXCEPTION"
            case 3043: return "BOOST_GEOMETRY_UNKNOWN_EXCEPTION"
            case 3044: return "STD_BAD_ALLOC_ERROR"
            case 3045: return "STD_DOMAIN_ERROR"
            case 3046: return "STD_LENGTH_ERROR"
            case 3047: return "STD_INVALID_ARGUMENT"
            case 3048: return "STD_OUT_OF_RANGE_ERROR"
            case 3049: return "STD_OVERFLOW_ERROR"
            case 3050: return "STD_RANGE_ERROR"
            case 3051: return "STD_UNDERFLOW_ERROR"
            case 3052: return "STD_LOGIC_ERROR"
            case 3053: return "STD_RUNTIME_ERROR"
            case 3054: return "STD_UNKNOWN_EXCEPTION"
            case 3055: return "GIS_DATA_WRONG_ENDIANESS"
            case 3056: return "CHANGE_MASTER_PASSWORD_LENGTH"
            case 3057: return "USER_LOCK_WRONG_NAME"
            case 3058: return "USER_LOCK_DEADLOCK"
            case 3059: return "REPLACE_INACCESSIBLE_ROWS"
            case 3060: return "ALTER_OPERATION_NOT_SUPPORTED_REASON_GIS"
            case 3061: return "ILLEGAL_USER_VAR"
            case 3062: return "GTID_MODE_OFF"
            case 3063: return "UNSUPPORTED_BY_REPLICATION_THREAD"
            case 3064: return "INCORRECT_TYPE"
            case 3065: return "FIELD_IN_ORDER_NOT_SELECT"
            case 3066: return "AGGREGATE_IN_ORDER_NOT_SELECT"
            case 3067: return "INVALID_RPL_WILD_TABLE_FILTER_PATTERN"
            case 3068: return "NET_OK_PACKET_TOO_LARGE"
            case 3069: return "INVALID_JSON_DATA"
            case 3070: return "INVALID_GEOJSON_MISSING_MEMBER"
            case 3071: return "INVALID_GEOJSON_WRONG_TYPE"
            case 3072: return "INVALID_GEOJSON_UNSPECIFIED"
            case 3073: return "DIMENSION_UNSUPPORTED"
            case 3074: return "SLAVE_CHANNEL_DOES_NOT_EXIST"
            case 3075: return "SLAVE_MULTIPLE_CHANNELS_HOST_PORT"
            case 3076: return "SLAVE_CHANNEL_NAME_INVALID_OR_TOO_LONG"
            case 3077: return "SLAVE_NEW_CHANNEL_WRONG_REPOSITORY"
            case 3078: return "SLAVE_CHANNEL_DELETE"
            case 3079: return "SLAVE_MULTIPLE_CHANNELS_CMD"
            case 3080: return "SLAVE_MAX_CHANNELS_EXCEEDED"
            case 3081: return "SLAVE_CHANNEL_MUST_STOP"
            case 3082: return "SLAVE_CHANNEL_NOT_RUNNING"
            case 3083: return "SLAVE_CHANNEL_WAS_RUNNING"
            case 3084: return "SLAVE_CHANNEL_WAS_NOT_RUNNING"
            case 3085: return "SLAVE_CHANNEL_SQL_THREAD_MUST_STOP"
            case 3086: return "SLAVE_CHANNEL_SQL_SKIP_COUNTER"
            case 3087: return "WRONG_FIELD_WITH_GROUP_V2: "
            case 3088: return "MIX_OF_GROUP_FUNC_AND_FIELDS_V2: "
            case 3089: return "WARN_DEPRECATED_SYSVAR_UPDATE"
            case 3090: return "WARN_DEPRECATED_SQLMODE"
            case 3091: return "CANNOT_LOG_PARTIAL_DROP_DATABASE_WITH_GTID"
            case 3092: return "GROUP_REPLICATION_CONFIGURATION"
            case 3093: return "GROUP_REPLICATION_RUNNING"
            case 3094: return "GROUP_REPLICATION_APPLIER_INIT_ERROR"
            case 3095: return "GROUP_REPLICATION_STOP_APPLIER_THREAD_TIMEOUT"
            case 3096: return "GROUP_REPLICATION_COMMUNICATION_LAYER_SESSION_ERROR"
            case 3097: return "GROUP_REPLICATION_COMMUNICATION_LAYER_JOIN_ERROR"
            case 3098: return "BEFORE_DML_VALIDATION_ERROR"
            case 3099: return "PREVENTS_VARIABLE_WITHOUT_RBR"
            case 3100: return "RUN_HOOK_ERROR"
            case 3101: return "TRANSACTION_ROLLBACK_DURING_COMMIT"
            case 3102: return "GENERATED_COLUMN_FUNCTION_IS_NOT_ALLOWED"
            case 3103: return "UNSUPPORTED_ALTER_INPLACE_ON_VIRTUAL_COLUMN"
            case 3104: return "WRONG_FK_OPTION_FOR_GENERATED_COLUMN"
            case 3105: return "NON_DEFAULT_VALUE_FOR_GENERATED_COLUMN"
            case 3106: return "UNSUPPORTED_ACTION_ON_GENERATED_COLUMN"
            case 3107: return "GENERATED_COLUMN_NON_PRIOR"
            case 3108: return "DEPENDENT_BY_GENERATED_COLUMN"
            case 3109: return "GENERATED_COLUMN_REF_AUTO_INC"
            case 3110: return "FEATURE_NOT_AVAILABLE"
            case 3111: return "CANT_SET_GTID_MODE"
            case 3112: return "CANT_USE_AUTO_POSITION_WITH_GTID_MODE_OFF"
            case 3113: return "CANT_REPLICATE_ANONYMOUS_WITH_AUTO_POSITION"
            case 3114: return "CANT_REPLICATE_ANONYMOUS_WITH_GTID_MODE_ON"
            case 3115: return "CANT_REPLICATE_GTID_WITH_GTID_MODE_OFF"
            case 3116: return "CANT_SET_ENFORCE_GTID_CONSISTENCY_ON_WITH_ONGOING_GTID_VIOLATING_TRANSACTIONS"
            case 3117: return "SET_ENFORCE_GTID_CONSISTENCY_WARN_WITH_ONGOING_GTID_VIOLATING_TRANSACTIONS"
            case 3118: return "ACCOUNT_HAS_BEEN_LOCKED"
            case 3119: return "WRONG_TABLESPACE_NAME"
            case 3120: return "TABLESPACE_IS_NOT_EMPTY"
            case 3121: return "WRONG_FILE_NAME"
            case 3122: return "BOOST_GEOMETRY_INCONSISTENT_TURNS_EXCEPTION"
            case 3123: return "WARN_OPTIMIZER_HINT_SYNTAX_ERROR"
            case 3124: return "WARN_BAD_MAX_EXECUTION_TIME"
            case 3125: return "WARN_UNSUPPORTED_MAX_EXECUTION_TIME"
            case 3126: return "WARN_CONFLICTING_HINT"
            case 3127: return "WARN_UNKNOWN_QB_NAME"
            case 3128: return "UNRESOLVED_HINT_NAME"
            case 3129: return "WARN_ON_MODIFYING_GTID_EXECUTED_TABLE"
            case 3130: return "PLUGGABLE_PROTOCOL_COMMAND_NOT_SUPPORTED"
            case 3131: return "LOCKING_SERVICE_WRONG_NAME"
            case 3132: return "LOCKING_SERVICE_DEADLOCK"
            case 3133: return "LOCKING_SERVICE_TIMEOUT"
            case 3134: return "GIS_MAX_POINTS_IN_GEOMETRY_OVERFLOWED"
            case 3135: return "SQL_MODE_MERGED"
            case 3136: return "VTOKEN_PLUGIN_TOKEN_MISMATCH"
            case 3137: return "VTOKEN_PLUGIN_TOKEN_NOT_FOUND"
            case 3138: return "CANT_SET_VARIABLE_WHEN_OWNING_GTID"
            case 3139: return "SLAVE_CHANNEL_OPERATION_NOT_ALLOWED"
            case 3140: return "INVALID_JSON_TEXT"
            case 3141: return "INVALID_JSON_TEXT_IN_PARAM"
            case 3142: return "INVALID_JSON_BINARY_DATA"
            case 3143: return "INVALID_JSON_PATH"
            case 3144: return "INVALID_JSON_CHARSET"
            case 3145: return "INVALID_JSON_CHARSET_IN_FUNCTION"
            case 3146: return "INVALID_TYPE_FOR_JSON"
            case 3147: return "INVALID_CAST_TO_JSON"
            case 3148: return "INVALID_JSON_PATH_CHARSET"
            case 3149: return "INVALID_JSON_PATH_WILDCARD"
            case 3150: return "JSON_VALUE_TOO_BIG"
            case 3151: return "JSON_KEY_TOO_BIG"
            case 3152: return "JSON_USED_AS_KEY"
            case 3153: return "JSON_VACUOUS_PATH"
            case 3154: return "JSON_BAD_ONE_OR_ALL_ARG"
            case 3155: return "NUMERIC_JSON_VALUE_OUT_OF_RANGE"
            case 3156: return "INVALID_JSON_VALUE_FOR_CAST"
            case 3157: return "JSON_DOCUMENT_TOO_DEEP"
            case 3158: return "JSON_DOCUMENT_NULL_KEY"
            case 3159: return "SECURE_TRANSPORT_REQUIRED"
            case 3160: return "NO_SECURE_TRANSPORTS_CONFIGURED"
            case 3161: return "DISABLED_STORAGE_ENGINE"
            case 3162: return "USER_DOES_NOT_EXIST"
            case 3163: return "USER_ALREADY_EXISTS"
            case 3164: return "AUDIT_API_ABORT"
            case 3165: return "INVALID_JSON_PATH_ARRAY_CELL"
            case 3166: return "BUFPOOL_RESIZE_INPROGRESS"
            case 3167: return "FEATURE_DISABLED_SEE_DOC"
            case 3168: return "SERVER_ISNT_AVAILABLE"
            case 3169: return "SESSION_WAS_KILLED"
            case 3170: return "CAPACITY_EXCEEDED"
            case 3171: return "CAPACITY_EXCEEDED_IN_RANGE_OPTIMIZER"
            case 3172: return "TABLE_NEEDS_UPG_PART"
            case 3173: return "CANT_WAIT_FOR_EXECUTED_GTID_SET_WHILE_OWNING_A_GTID"
            case 3174: return "CANNOT_ADD_FOREIGN_BASE_COL_VIRTUAL"
            case 3175: return "CANNOT_CREATE_VIRTUAL_INDEX_CONSTRAINT"
            case 3176: return "ERROR_ON_MODIFYING_GTID_EXECUTED_TABLE"
            case 3177: return "LOCK_REFUSED_BY_ENGINE"
            case 3178: return "UNSUPPORTED_ALTER_ONLINE_ON_VIRTUAL_COLUMN"
            case 3179: return "MASTER_KEY_ROTATION_NOT_SUPPORTED_BY_SE"
            case 3180: return "MASTER_KEY_ROTATION_ERROR_BY_SE"
            case 3181: return "MASTER_KEY_ROTATION_BINLOG_FAILED"
            case 3182: return "MASTER_KEY_ROTATION_SE_UNAVAILABLE"
            case 3183: return "TABLESPACE_CANNOT_ENCRYPT"
            case 3184: return "INVALID_ENCRYPTION_OPTION"
            case 3185: return "CANNOT_FIND_KEY_IN_KEYRING"
            case 3186: return "CAPACITY_EXCEEDED_IN_PARSER"
            case 3187: return "UNSUPPORTED_ALTER_ENCRYPTION_INPLACE"
            case 3188: return "KEYRING_UDF_KEYRING_SERVICE_ERROR"
            case 3189: return "USER_COLUMN_OLD_LENGTH"
            case 3190: return "CANT_RESET_MASTER"
            case 3191: return "GROUP_REPLICATION_MAX_GROUP_SIZE"
            case 3192: return "CANNOT_ADD_FOREIGN_BASE_COL_STORED"
            case 3193: return "TABLE_REFERENCED"
            default: return "UNKNOWN"
            }
        }
        
        public init?(rawValue: UInt16) {
            self.rawValue = rawValue
        }
        
        public init(integerLiteral value: UInt16) {
            self.rawValue = value
        }
    }
}
