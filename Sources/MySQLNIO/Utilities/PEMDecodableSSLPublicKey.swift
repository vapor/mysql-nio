import NIOSSL
#if compiler(>=5.1) && compiler(<5.3)
@_implementationOnly import CNIOBoringSSL
#else
import CNIOBoringSSL
#endif

enum MoreNIOSSLErrors: Error {
    case failedToLoadPublicKey
    
    /// To add final insult to the injury of all this copy-pasta, thanks to the differing typealias,
    /// we can't even use the original error enum itself in the end.
    case unknownBoringSSLError(MoreNIOBoringSSLNotCoweringInCupertinoErrorStack)

    public static var unknownStack: Self {
        return .unknownBoringSSLError(self.buildNotUnreasonablyHiddenErrorStack())
    }

    /// For some reason, this utility on `BoringSSLError` is not public, so now we
    /// duplicate it exactly here, with the accompanying maintenance burden, even
    /// though we don't need our own version for any reason.
    public static func buildNotUnreasonablyHiddenErrorStack() -> MoreNIOBoringSSLNotCoweringInCupertinoErrorStack {
        var errorStack = MoreNIOBoringSSLNotCoweringInCupertinoErrorStack()
        
        while true {
            let errorCode = CNIOBoringSSL_ERR_get_error()
            if errorCode == 0 { break }
            errorStack.append(BoringSSLInternalButLegitimateAndUsableError(errorCode: errorCode))
        }
        return errorStack
    }
}

/// Same goes for this entire struct. Absurd.
public struct BoringSSLInternalButLegitimateAndUsableError: Equatable, CustomStringConvertible {
    public let errorCode: UInt32

    public var errorMessage: String {
        var scratchBuffer = [CChar](repeating: 0, count: 512)
        return scratchBuffer.withUnsafeMutableBufferPointer { pointer in
            CNIOBoringSSL_ERR_error_string_n(self.errorCode, pointer.baseAddress!, pointer.count)
            return String(cString: pointer.baseAddress!)
        }
    }

    public var description: String { "Error: \(errorCode) \(errorMessage)" }
    public init(errorCode: UInt32) { self.errorCode = errorCode }
}

/// And because we changed the struct's name, we can't use the existing
/// typealias, even though that's the one thing that DID bother being public!!
public typealias MoreNIOBoringSSLNotCoweringInCupertinoErrorStack = [BoringSSLInternalButLegitimateAndUsableError]

/// It turns out there are _no_ public ways whatsoever to create an
/// `NIOSSLPublicKey`, even though all we wanted to do was add a way to invoke
/// one the same way the private and X.509 types can be invoked. So now we have
/// to copy the whole bloody thing.
public class MoreNIOSSLPublicKey {
    private let _ref: UnsafeMutableRawPointer /*<EVP_PKEY>*/

    private var ref: UnsafeMutablePointer<EVP_PKEY> {
        return self._ref.assumingMemoryBound(to: EVP_PKEY.self)
    }

    fileprivate init(withOwnedReference ref: UnsafeMutablePointer<EVP_PKEY>) {
        self._ref = UnsafeMutableRawPointer(ref) // erasing the type for @_implementationOnly import CNIOBoringSSL
    }

    deinit {
        CNIOBoringSSL_EVP_PKEY_free(self.ref)
    }

    /// Create an NIOSSLPrivateKey from a buffer of bytes in either PEM or
    /// DER format.
    ///
    /// - parameters:
    ///     - bytes: The key bytes.
    ///     - format: The format of the key to load, either DER or PEM.
    public convenience init(bytes: [UInt8], format: NIOSSLSerializationFormats) throws {
        let ref = bytes.withUnsafeBytes { (ptr) -> UnsafeMutablePointer<EVP_PKEY>? in
            let bio = CNIOBoringSSL_BIO_new_mem_buf(ptr.baseAddress!, CInt(ptr.count))!
            defer {
                CNIOBoringSSL_BIO_free(bio)
            }

            switch format {
            case .pem:
                return CNIOBoringSSL_PEM_read_bio_PUBKEY(bio, nil, { _, _, _, _  in -1 }, nil)
            case .der:
                return CNIOBoringSSL_d2i_PUBKEY_bio(bio, nil)
            }
        }

        if ref == nil {
            throw MoreNIOSSLErrors.failedToLoadPublicKey
        }

        self.init(withOwnedReference: ref!)
    }
}

// MARK:- Utilities
extension MoreNIOSSLPublicKey {
    /// Perform an RSA asymmetric "encrypt" operation, such that the matching private key for this public key
    /// is required to later decrypt the result and recover the original plaintext. This function allocates,
    /// somewhat out of necessity. The use of PKCS#1 OAEP padding is hardcoded at this time. This is the padding
    /// used by MySQL's "caching_sha2_password" plugin. The return value is the resultant ciphertext, already
    /// padded according to PKCS#1 rules. This function can only encrypt a single "block"; it does not implement
    /// any codebook modes whatsoever. An input which exceeds the limit will be rejected, not truncated
    public func encrypt(bytes: [UInt8]) throws -> [UInt8] {
        guard let context = CNIOBoringSSL_EVP_PKEY_CTX_new(self.ref, nil) else {
            throw MoreNIOSSLErrors.unknownStack
        }
        defer { CNIOBoringSSL_EVP_PKEY_CTX_free(context) }
        
        guard CNIOBoringSSL_EVP_PKEY_encrypt_init(context) > 0 else { throw MoreNIOSSLErrors.unknownStack }
        guard CNIOBoringSSL_EVP_PKEY_CTX_set_rsa_padding(context, RSA_PKCS1_OAEP_PADDING) > 0 else { throw MoreNIOSSLErrors.unknownStack }
        
        var ciphertextLength: Int = 0
        
        return try bytes.withUnsafeBufferPointer { inputBuffer in
            guard CNIOBoringSSL_EVP_PKEY_encrypt(context, nil, &ciphertextLength, inputBuffer.baseAddress, inputBuffer.count) > 0 else {
                throw MoreNIOSSLErrors.unknownStack
            }
            
            return try [UInt8].init(unsafeUninitializedCapacity: ciphertextLength) { outputBuffer, outCount in
                outCount = ciphertextLength
                guard CNIOBoringSSL_EVP_PKEY_encrypt(context, outputBuffer.baseAddress, &outCount, inputBuffer.baseAddress, inputBuffer.count) > 0 else {
                    throw MoreNIOSSLErrors.unknownStack
                }
            }
        }
    }

    public static func ==(lhs: MoreNIOSSLPublicKey, rhs: MoreNIOSSLPublicKey) -> Bool {
        // Annoyingly, EVP_PKEY_cmp does not have a traditional return value pattern. 1 means equal, 0 means non-equal,
        // negative means error. Here we treat "error" as "not equal", because we have no error reporting mechanism from this call site,
        // and anyway, BoringSSL considers "these keys aren't of the same type" to be an error, which is in my mind pretty ludicrous.
        return CNIOBoringSSL_EVP_PKEY_cmp(lhs.ref, rhs.ref) == 1
    }
}
