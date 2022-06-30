import Crypto
import Foundation

internal struct MySQLAuthPluginNativePassword: MySQLAuthPluginResponder {
    init() {}
    
    var hasAlreadyResponded: Bool = false
    
    func handle(pluginName: String, configuration: MySQLConnection.Configuration, isSecureConnection: Bool, data: [UInt8]) throws -> [UInt8]? {
        assert(pluginName == "mysql_native_password")
        
        guard !self.hasAlreadyResponded else {
            throw MySQLError.protocolError
        }
        self.hasAlreadyResponded = true
        
        guard data.count == 20 else {
            throw MySQLError.protocolError
        }
        
        guard let password = configuration.authentication.password, !password.isEmpty else {
            // Empty or unspecified password - return empty data.
            return []
        }
        
        /// [MySQL Internals Manual § 14.3.3](https://dev.mysql.com/doc/internals/en/secure-password-authentication.html):
        ///
        /// The password is calculated by:
        ///
        ///     SHA1( password ) XOR SHA1( "20-bytes random data from server" <concat> SHA1( SHA1( password ) ) )
        let passwordSha1 = Insecure.SHA1.hash(data: Array(password.utf8)),
            saltedPasswordSha1 = Insecure.SHA1.hash(data: data + Array(Insecure.SHA1.hash(data: Array(passwordSha1)))),
            passwordSha1XorSaltEtc = zip(passwordSha1, saltedPasswordSha1).map { $0 ^ $1 }
        
        assert(passwordSha1XorSaltEtc.count == 20)
        return passwordSha1XorSaltEtc
    }
}
