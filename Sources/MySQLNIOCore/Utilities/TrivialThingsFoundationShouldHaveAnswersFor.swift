import Foundation

extension ProcessInfo {

    /// Generated with `bash`:
    ///
    /// ```bash
    /// for i in {10..7}; do
    ///     for j in {10..0}; do
    ///         echo "        #elseif swift(>=5.$i.$j)"
    ///         echo "        return \"5.$i.$j\""
    ///     done
    /// done
    /// ```
    public var swiftRuntimeVersion: String {
        #if swift(>=5.10.10)
        return "5.10.10"
        #elseif swift(>=5.10.9)
        return "5.10.9"
        #elseif swift(>=5.10.8)
        return "5.10.8"
        #elseif swift(>=5.10.7)
        return "5.10.7"
        #elseif swift(>=5.10.6)
        return "5.10.6"
        #elseif swift(>=5.10.5)
        return "5.10.5"
        #elseif swift(>=5.10.4)
        return "5.10.4"
        #elseif swift(>=5.10.3)
        return "5.10.3"
        #elseif swift(>=5.10.2)
        return "5.10.2"
        #elseif swift(>=5.10.1)
        return "5.10.1"
        #elseif swift(>=5.10.0)
        return "5.10.0"
        #elseif swift(>=5.9.10)
        return "5.9.10"
        #elseif swift(>=5.9.9)
        return "5.9.9"
        #elseif swift(>=5.9.8)
        return "5.9.8"
        #elseif swift(>=5.9.7)
        return "5.9.7"
        #elseif swift(>=5.9.6)
        return "5.9.6"
        #elseif swift(>=5.9.5)
        return "5.9.5"
        #elseif swift(>=5.9.4)
        return "5.9.4"
        #elseif swift(>=5.9.3)
        return "5.9.3"
        #elseif swift(>=5.9.2)
        return "5.9.2"
        #elseif swift(>=5.9.1)
        return "5.9.1"
        #elseif swift(>=5.9.0)
        return "5.9.0"
        #elseif swift(>=5.8.10)
        return "5.8.10"
        #elseif swift(>=5.8.9)
        return "5.8.9"
        #elseif swift(>=5.8.8)
        return "5.8.8"
        #elseif swift(>=5.8.7)
        return "5.8.7"
        #elseif swift(>=5.8.6)
        return "5.8.6"
        #elseif swift(>=5.8.5)
        return "5.8.5"
        #elseif swift(>=5.8.4)
        return "5.8.4"
        #elseif swift(>=5.8.3)
        return "5.8.3"
        #elseif swift(>=5.8.2)
        return "5.8.2"
        #elseif swift(>=5.8.1)
        return "5.8.1"
        #elseif swift(>=5.8.0)
        return "5.8.0"
        #elseif swift(>=5.7.10)
        return "5.7.10"
        #elseif swift(>=5.7.9)
        return "5.7.9"
        #elseif swift(>=5.7.8)
        return "5.7.8"
        #elseif swift(>=5.7.7)
        return "5.7.7"
        #elseif swift(>=5.7.6)
        return "5.7.6"
        #elseif swift(>=5.7.5)
        return "5.7.5"
        #elseif swift(>=5.7.4)
        return "5.7.4"
        #elseif swift(>=5.7.3)
        return "5.7.3"
        #elseif swift(>=5.7.2)
        return "5.7.2"
        #elseif swift(>=5.7.1)
        return "5.7.1"
        #elseif swift(>=5.7.0)
        return "5.7.0"
        #endif
    }

    /// Based on https://github.com/apple/swift/blob/main/lib/Basic/LangOptions.cpp#L52-L82
    public var operatingSystemPlainName: String {
        #if os(macOS)
        return "macOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(watchOS)
        return "watchOS"
        #elseif os(iOS)
        return "iOS"
        #elseif os(Linux)
        return "Linux"
        #elseif os(FreeBSD)
        return "FreeBSD"
        #elseif os(OpenBSD)
        return "OpenBSD"
        #elseif os(Windows)
        return "Windows"
        #elseif os(Android)
        return "Android"
        #elseif os(PS4)
        return "PS4"
        #elseif os(Cygwin)
        return "Cygwin"
        #elseif os(Haiku)
        return "Haiku"
        #elseif os(WASI)
        return "WASI"
        #else
        return "unknown"
        #endif
    }
    
    /// Based on https://github.com/apple/swift/blob/main/lib/Basic/LangOptions.cpp#L52-L82
    public var hostArchitectureName: String {
        #if arch(arm)
        return "arm"
        #elseif arch(arm64)
        return "arm64"
        #elseif arch(arm64_32)
        return "arm64_32"
        #elseif arch(i386)
        return "i386"
        #elseif arch(x86_64)
        return "x86_64"
        #elseif arch(powerpc)
        return "powerpc"
        #elseif arch(powerpc64)
        return "powerpc64"
        #elseif arch(powerpc64le)
        return "powerpc64le"
        #elseif arch(s390x)
        return "s390x"
        #elseif arch(wasm32)
        return "wasm32"
        #else
        return "unknown"
        #endif
    }

}
