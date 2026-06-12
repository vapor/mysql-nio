#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

extension ProcessInfo {
    /// Generated with `bash`:
    ///
    /// ```bash
    /// for i in {3..2}; do
    ///     for j in {10..0}; do
    ///         echo "        #elseif swift(>=6.$i.$j)"
    ///         echo "        return \"6.$i.$j\""
    ///     done
    /// done
    /// ```
    var swiftRuntimeVersion: String {
        #if swift(>=6.3.2)
        "6.3.2"
        #elseif swift(>=6.3.1)
        "6.3.1"
        #elseif swift(>=6.3.0)
        "6.3.0"
        #elseif swift(>=6.2.4)
        "6.2.4"
        #elseif swift(>=6.2.3)
        "6.2.3"
        #elseif swift(>=6.2.2)
        "6.2.2"
        #elseif swift(>=6.2.1)
        "6.2.1"
        #elseif swift(>=6.2.0)
        "6.2.0"
        #endif
    }

    /// Based on https://github.com/apple/swift/blob/main/lib/Basic/LangOptions.cpp#L52-L82
    var operatingSystemPlainName: String {
        #if os(macOS)
        "macOS"
        #elseif os(tvOS)
        "tvOS"
        #elseif os(watchOS)
        "watchOS"
        #elseif os(iOS)
        "iOS"
        #elseif os(Linux)
        "Linux"
        #elseif os(FreeBSD)
        "FreeBSD"
        #elseif os(OpenBSD)
        "OpenBSD"
        #elseif os(Windows)
        "Windows"
        #elseif os(Android)
        "Android"
        #elseif os(PS4)
        "PS4"
        #elseif os(Cygwin)
        "Cygwin"
        #elseif os(Haiku)
        "Haiku"
        #elseif os(WASI)
        "WASI"
        #else
        "unknown"
        #endif
    }

    /// Based on https://github.com/apple/swift/blob/main/lib/Basic/LangOptions.cpp#L52-L82
    var hostArchitectureName: String {
        #if arch(arm)
        "arm"
        #elseif arch(arm64)
        "arm64"
        #elseif arch(arm64_32)
        "arm64_32"
        #elseif arch(i386)
        "i386"
        #elseif arch(x86_64)
        "x86_64"
        #elseif arch(powerpc)
        "powerpc"
        #elseif arch(powerpc64)
        "powerpc64"
        #elseif arch(powerpc64le)
        "powerpc64le"
        #elseif arch(s390x)
        "s390x"
        #elseif arch(wasm32)
        "wasm32"
        #else
        "unknown"
        #endif
    }
}
