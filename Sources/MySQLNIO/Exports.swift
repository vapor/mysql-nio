#if swift(>=5.8)

@_documentation(visibility: internal) @_exported import NIO
@_documentation(visibility: internal) @_exported import struct Logging.Logger
@_documentation(visibility: internal) @_exported import struct NIOSSL.TLSConfiguration
@_documentation(visibility: internal) @_exported import struct Foundation.Date
@_documentation(visibility: internal) @_exported import struct Foundation.UUID
@_documentation(visibility: internal) @_exported import struct Foundation.Decimal

#else

@_exported import NIO
@_exported import struct Logging.Logger
@_exported import struct NIOSSL.TLSConfiguration
@_exported import struct Foundation.Date
@_exported import struct Foundation.UUID
@_exported import struct Foundation.Decimal

#endif
