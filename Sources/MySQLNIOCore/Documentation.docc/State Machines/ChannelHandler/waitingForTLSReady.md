# ``MySQLNIOCore/MySQLChannel/Handler/State/waitingForTLSReady(handshake:)``

## Overview

This state indicates that a TLS connection was configured, the appropriate request has been sent to the server, and the connection is awaiting confirmation from the TLS implementation layer.

The auth data from the server handshake is preserved during this state, as it is needed in order to send the full handshake reply once TLS setup is complete. Other interesting data from the server handshake - such as the set of negotiated capability flags - is preserved in the state machine on a more global basis

### Transitions

- `closed`
- `awaitingAuthReply`
