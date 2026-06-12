/// A MySQL server address to connect to.
public struct MySQLServerAddress: Sendable, Equatable, Hashable {
    enum _Internal: Equatable, Hashable {
        case hostname(_ host: String, port: Int)
        case unixDomainSocket(path: String)
    }

    let value: _Internal
    init(_ value: _Internal) {
        self.value = value
    }

    /// Address defined by host and port.
    ///
    /// - Parameters:
    ///   - host: The hostname or IP address of the MySQL server.
    ///   - port: The port number of the MySQL server. Default is `3306`.
    public static func hostname(_ host: String, port: Int = 3306) -> Self { .init(.hostname(host, port: port)) }

    /// Address defined by Unix domain socket.
    ///
    /// - Parameter path: The file system path of the Unix domain socket.
    public static func unixDomainSocket(path: String) -> Self { .init(.unixDomainSocket(path: path)) }
}
