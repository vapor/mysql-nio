# ``MySQLNIOCore/MySQLChannel/Handler/State``

This state machine is responsible for the overall operation of a MySQL connection, starting with the initial handshake. It delegates most behaviors to various other purpose-specific state machines as appropriate. 

## State Diagram

![State diagram](ChannelHandlerStateMachine.svg)
<!--
%%{ init: { 'flowchart': { 'htmlLabels': false, 'rankSpacing': 75, 'diagramPadding': 50, 'curve': 'monotoneY' } } }%%
flowchart TB
  classDef default font-family:monospace,font-size:13px;
  linkStyle default stroke-width:1px;
  startup([startup]) -- channel active --&gt; auth
  subgraph auth
    direction TB
    awaitingGreeting -- TLS enabled --&gt; waitingForTLSReady
    awaitingGreeting -- no TLS --&gt; awaitingAuthReply
    waitingForTLSReady -- TLS started --&gt; awaitingAuthReply
    awaitingAuthReply --&gt; awaitingAuthReply
  end
  auth --&gt; active
  subgraph active
  direction TB
  idle
  idle -- ping, reset, db, stats --&gt; awaitingOK
  idle -- plain query --&gt; runningPlainQuery
  idle -- prepare --&gt; preparingStatement
  idle -- execute --&gt; executingStatement
  idle -- fetch --&gt; fetchingCursorData
  awaitingOK --&gt; idle
  awaitingOK --&gt; awaitingOK
  awaitingOK --&gt; runningPlainQuery
  awaitingOK --&gt; preparingStatement
  awaitingOK --&gt; executingStatement
  awaitingOK --&gt; fetchingCursorData
  runningPlainQuery --&gt; awaitingOK
  runningPlainQuery --&gt; runningPlainQuery
  runningPlainQuery --&gt; preparingStatement
  runningPlainQuery --&gt; executingStatement
  runningPlainQuery --&gt; fetchingCursorData
  runningPlainQuery --&gt; idle
  preparingStatement --&gt; awaitingOK
  preparingStatement --&gt; runningPlainQuery
  preparingStatement --&gt; preparingStatement
  preparingStatement --&gt; executingStatement
  preparingStatement --&gt; fetchingCursorData
  preparingStatement --&gt; idle
  executingStatement --&gt; awaitingOK
  executingStatement --&gt; runningPlainQuery
  executingStatement --&gt; preparingStatement
  executingStatement --&gt; executingStatement
  executingStatement --&gt; fetchingCursorData
  executingStatement --&gt; idle
  fetchingCursorData --&gt; awaitingOK
  fetchingCursorData --&gt; runningPlainQuery
  fetchingCursorData --&gt; preparingStatement
  fetchingCursorData --&gt; executingStatement
  fetchingCursorData --&gt; fetchingCursorData
  fetchingCursorData --&gt; idle
  end
  subgraph error
  terminated([terminated])
  end
  subgraph quit
  closed([closed])
  end
  active --&gt; quit
  active --&gt; error
  auth --&gt; error
-->

