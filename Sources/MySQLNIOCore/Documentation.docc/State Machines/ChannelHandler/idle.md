# ``MySQLNIOCore/MySQLChannel/Handler/State/idle``

This is effectively a connection's "idle" state. It may or may not occur between commands if
multiple commands are queued.

> Note: This is the only state with outgoing transitions triggered solely by client-side actions.

### Transitions

- `awaitingOK`
- `gettingStatistics`
- `runningPlainQuery`
- `preparingStatement`
- `executingStatement`
- `fetchingCursorData`
- `closed`
