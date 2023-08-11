# ``MySQLNIOCore/MySQLBuiltinAuthHandlers/CachingSHA2/State``

This state machine is responsible for the handling of authentication with the `caching_sha256_password` overall operation of a MySQL connection, starting with the initial handshake. It delegates most behaviors to various other purpose-specific state machines as appropriate. 

## State Diagram

![State diagram](CachingSHA2AuthHandlerStateMachine.svg)
<!--
%%{ init: { 'flowchart': { 'htmlLabels': false, 'rankSpacing': 50, 'diagramPadding': 50, 'curve': 'basis' } } }%%
flowchart TB
  classDef default font-family:monospace,font-size:13px;
  linkStyle default stroke-width:1px;
  
  awaitingNonce([awaitingNonce])
  passwordSent([passwordSent])
  
  awaitingNonce -- non-empty password --&gt; sentFastAuth
  awaitingNonce -- empty password --&gt; passwordSent
  sentFastAuth -- success --&gt; passwordSent
  sentFastAuth -- failed (secure) --&gt; passwordSent
  sentFastAuth -- failed (insecure) --&gt; requestedServerKey
  requestedServerKey --&gt; passwordSent
-->

