extension Collection {
    subscript(idx: Self.Index, default default: Self.Element) -> Self.Element { self.indices.contains(idx) ? self[idx] : `default` }
}

extension MySQLProtocol {
    /// MySQL 5.7:          "5.7.38"
    /// MySQL 8.0:          "8.0.29"
    /// MariaDB 10.3:       "5.5.5-10.3.32-MariaDB"
    /// MariaDB 10.7:       "5.5.5-10.7.3-MariaDB"
    /// Percona Server 8.0: "8.0.28-19"
    /// Amazon Aurora 2.10: "5.7.12"
    /// Amazon Aurora 3.02: "8.0.23"
    struct ServerVersion: CustomStringConvertible {
        let raw: String
        let major: Int
        let minor: Int
        let patch: Int
        let additional: String
        let isMariaDB: Bool

        /// While the format of the versions various servers report for themselves seems surprisingly consistent, this
        /// "parser" nonetheless tries to be as forgiving as it can; better to come up with _something_ as a server
        /// version than to reject alternate formats unnecessarily.
        init?<S>(string: S) where S: StringProtocol {
            guard !string.isEmpty else { return nil }
            
            self.raw = .init(string)
            let pieces = string.split(separator: "-", omittingEmptySubsequences: false)
            assert(!pieces.isEmpty)
            
            let primaryParts = pieces[0].split(separator: ".", omittingEmptySubsequences: false)
            let (pMajor, pMinor, pPatch) = (Int(primaryParts[0, default: "0"]) ?? 0, Int(primaryParts[1, default: "0"]) ?? 0, Int(primaryParts[2, default: "0"]) ?? 0)
            
            let secondaryParts = pieces.dropFirst(1).first?.split(separator: ".", omittingEmptySubsequences: false) ?? []
            let (sMajor, sMinor, sPatch) = (Int(secondaryParts[0, default: "0"]) ?? 0, Int(secondaryParts[1, default: "0"]) ?? 0, Int(secondaryParts[2, default: "0"]) ?? 0)
            
            let remainder = pieces.dropFirst(2).first ?? ""
            
            if remainder.lowercased() == "mariadb" {
                self.major = sMajor
                self.minor = sMinor
                self.patch = sPatch
                self.additional = "\(pMajor).\(pMinor).\(pPatch)"
                self.isMariaDB = true
            } else {
                self.major = pMajor
                self.minor = pMinor
                self.patch = pPatch
                self.additional = pieces.dropFirst().joined(separator: "-")
                self.isMariaDB = false
            }
        }
        
        var description: String {
            "\(self.major).\(self.minor).\(self.patch)-\(self.additional)\(self.isMariaDB ? "-MariaDB" : "")"
        }
    }
}
