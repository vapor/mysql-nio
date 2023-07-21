# ``MySQLNIOCore/MySQLChannel/Handler/State/awaitingAuthReply(handshake:authHandler:secureConnection:)``

This state can occur multiple times during the auth process:

- After sending a handshake reply (expecting more auth steps or OK)
- After sending an auth switch response (expecting more auth steps or OK)
- After sending a "more data" reply (expecting more auth steps or OK)
- After sending a "next factor" reply (expecting more auth steps or OK)

### Transitions

- `awaitingAuthReply`
- `idle`
- `closed`
