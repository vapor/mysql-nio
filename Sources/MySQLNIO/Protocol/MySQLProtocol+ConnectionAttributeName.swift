import class Foundation.ProcessInfo

extension MySQLProtocol {
    
    struct ConnectionAttributeName: ExpressibleByStringLiteral, LosslessStringConvertible, RawRepresentable, Hashable, Codable {
        let name: String
        
        var description: String { self.name }
        var rawValue: String { self.name }
        
        init(name: String) { self.name = name }
        init?(_ description: String) { self.init(name: description) }
        init?(rawValue: RawValue) { self.init(name: rawValue) }
        init(stringLiteral value: String) { self.init(name: value) }
        
        static var clientName: Self { "_client_name" }
        static var clientVersion: Self { "_client_version" }
        static var os: Self { "_os" }
        static var pid: Self { "_pid" }
        static var platform: Self { "_platform" }
        static var threadId: Self { "_thread" }
        static var programName: Self { "program_name" }
        static var altProgramName: Self { "_program_name" }
        static var clientRole: Self { "_client_role" }
        
        /// Returns the set of connection attributes which will be sent by default on connections which support attributes if no
        /// overriding values are provided elsewhere.
        ///
        /// - Note: Only a subset of the predefined attribute names are included in this set. Attributes whose values could be considered
        ///   sensitive data, or whose retrieval would introduce contextual correctness issues, are excluded (specifically the process and
        ///   thread IDs). Attributes without obvious defaults (such as program name or client role) are also omitted.
        ///
        /// - Warning: This method does _**not**_ guarantee that it caches its results; assume that calling it may be relatively expensive,
        ///   even if that is not the observed behavior at any particular time.
        static func defaultAttributeValues() -> [ConnectionAttributeName: String] {
#if arch(i386)
            let arch = "i386"
#elseif arch(x86_64)
            let arch = "x86_64"
#elseif arch(arm)
            let arch = "arm"
#elseif arch(arm64)
            let arch = "arm64"
#else
            let arch = "unknown" // TODO: Should we try asking `uname()` here? What about on Windows?
#endif

#warning "Don't release without fixing the .clientVersion atrribute!"
            return [
                .clientName: "MySQLNIO",
                .clientVersion: "1.5.0", // TODO: Figure out a way to put a real value here. Do NOT let this become an arbitrary hardcoded value.
                .os: ProcessInfo.processInfo.operatingSystemVersionString,
                .platform: arch,
            ]
        }
    }
    
}
