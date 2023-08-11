# ``MySQLNIOCore/MySQLChannel/Handler/State/closed``

This is a terminal state; the connection is no longer usable.

This state is reached only from the reply to a `COM_QUIT` command, or as a side effect of a
user request to close the channel. It indicates a connection which experienced no errors and
was gracefully shut down from the client side.

### Transitions

_terminal_
