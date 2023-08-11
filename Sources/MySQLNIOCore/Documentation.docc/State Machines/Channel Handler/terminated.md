# ``MySQLNIOCore/MySQLChannel/Handler/State/terminated(error:)``

This is a terminal state; the connection is no longer usable.

This state occurs when, in any other state, any error which leaves the connection unusable occurs. This includes "connection closed" errors, server ERR packets with certain error codes, etc. It does _not_ include transient failures such as query parsing errors or constraint violations, nor does it occur as a result of "normal" client connection termination (such as by a `COM_QUIT` command).

### Transitions

_terminal_
