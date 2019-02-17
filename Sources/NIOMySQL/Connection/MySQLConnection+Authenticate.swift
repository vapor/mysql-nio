//extension MySQLConnection {
//    public func authenticate(
//        username: String,
//        database: String,
//        password: String? = nil,
//        tlsConfig: TLSConfiguration? = nil
//    ) -> EventLoopFuture<Void> {
//        let auth = MySQLAuthenticationRequest(
//            username: username,
//            database: database,
//            password: password
//        )
//        return self.send(auth)
//    }
//}
//
//private final class MySQLAuthenticationRequest: MySQLRequestHandler {
//    enum State {
//        case nascent
//        case sha2
//        case native(MySQLCapabilityFlags)
//    }
//
//    var state: State
//
//
//    init(username: String, database: String, password: String?, tlsConfig: TLSConfiguration?) {
//        self.state = .nascent
//        self.username = username
//        self.database = database
//        self.password = password
//        self.tlsConfig = tlsConfig
//    }
//
//}
