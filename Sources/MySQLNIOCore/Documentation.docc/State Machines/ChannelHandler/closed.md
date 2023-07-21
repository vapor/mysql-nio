# ``MySQLNIOCore/MySQLChannel/Handler/State/closed(reason:)``

This is a terminal state; the connection is no longer usable.

This state is reached only once the channel is inactive. The reason, if not `nil`, indicates
the condition which caused the channel's closure; `nil` indicates that the channel was closed
in orderly fashion by client request.

### Transitions

_terminal_
