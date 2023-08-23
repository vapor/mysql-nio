# ``MySQLNIOCore/MySQLChannel/Handler/State``

This state machine is responsible for the overall operation of a MySQL connection, starting with the initial handshake

## State Diagram

![State diagram](https://mermaid.ink/svg/pako:eNqFllFv0zAQx7_KEdR1SOkEPOwhY0iwaTxsaLDubeHBjS-NNccOjkNXVf3unJMMOnIWD1Xs8-989_9v0nmXFFZikiWz2Q6UUT6DXW4A5qU1_krUSm_nGcxra2zbiALnaX_qK6wxHKxE-yJ2sVyG8AnKNS58pYpHg207rGAHrXf2ERcbJX2VwbvmCV6purHOC-PPYA8nhroBh4UnuFRaZ_C6LMuzfr2w1IHyW0o8G2-i49PTU8oceyi13RSVcJ6a2M0rX-sbsULd0rYUusUU5o2QUpk1Rd6_3edmD_vZLDd_EuH-c7ip9bTumuOHcfHjTW76eLdaO9FUIDpfhQCAVKFfZc2YCiA2Qnmq8cUhhi-cn8P9zRLQiJVGSduPMCJX1tHJHQq5jeca26eHtOfjT1T-Dhs9Zk1ve67Z9z_WjCRPwnEYjQyf8FNSI3ygKnnSEJbSX61Fn4aCvk3hZ4dum0LjsBGOfMcnLDpPixJ9UeXJUIN8-4X_OjsGp84-t3R7_aLD22vmcI0-7JbUjWq9KlqGcZ0xtPumhTLfQ78MMwgYb6J_cOMZaBD3H6gXTtuLzrXWXQovAjTpk5HGM6xCHmWF8iivl2d52TzLq580xqjnGVY9j7LqeZRXz7O8ep7l1U-rMfIjEKs_wrIGRFjegQjMWxCBeQ-mVzAeRCDWgwjLehBheQ8iMO9BBOY9mEYZDyIQ60GEZT2IsLwHEZj3IAJzHhzMljBYey4MmINRDGGi0Yg2BvU4IwaXxkEcfoW2Lcrjh-EbZvbf9KNhYh0dzJeDW4aMEEzSpEZXCyXpVdS_hfKkf9rkSUZLiaXotM8TejoQStXtcmuKJPOuwzTpGkkOXCpBs6xOsuHRkaBU3rqvw0urf3DtfwOJkmOl)
<!--
%%{ init: {
  'fontFamily': 'monospace',
  'theme': 'base',
  'themeCSS': '.edge-thickness-thick { stroke-width: 1px !important; } .node rect { fill: #fff; fill-opacity: 1; stroke: #666; }',
  'flowchart': {'htmlLabels': false, 'padding': 20}
} }%%
flowchart TB
  startup([startup])

  subgraph auth
    direction TB
    awaitingGreeting == TLS enabled ==> waitingForTLSReady
    awaitingGreeting == no TLS ==> awaitingAuthReply
    waitingForTLSReady == TLS started ==> awaitingAuthReply
    awaitingAuthReply ==> awaitingAuthReply
  end
  
  idle <== "ping, reset, stats, query, prepare, execute, fetch" ==> active

  subgraph active
  direction TB
  awaitingOK ==> awaitingOK
  awaitingOK ==> gettingStatistics
  awaitingOK ==> runningPlainQuery
  awaitingOK ==> preparingStatement
  awaitingOK ==> executingStatement
  awaitingOK ==> fetchingCursorData
  gettingStatistics ==> awaitingOK
  gettingStatistics ==> gettingStatistics
  gettingStatistics ==> runningPlainQuery
  gettingStatistics ==> preparingStatement
  gettingStatistics ==> executingStatement
  gettingStatistics ==> fetchingCursorData
  runningPlainQuery ==> awaitingOK
  runningPlainQuery ==> gettingStatistics
  runningPlainQuery ==> runningPlainQuery
  runningPlainQuery ==> preparingStatement
  runningPlainQuery ==> executingStatement
  runningPlainQuery ==> fetchingCursorData
  preparingStatement ==> awaitingOK
  preparingStatement ==> gettingStatistics
  preparingStatement ==> runningPlainQuery
  preparingStatement ==> preparingStatement
  preparingStatement ==> executingStatement
  preparingStatement ==> fetchingCursorData
  executingStatement ==> awaitingOK
  executingStatement ==> gettingStatistics
  executingStatement ==> runningPlainQuery
  executingStatement ==> preparingStatement
  executingStatement ==> executingStatement
  executingStatement ==> fetchingCursorData
  fetchingCursorData ==> awaitingOK
  fetchingCursorData ==> gettingStatistics
  fetchingCursorData ==> runningPlainQuery
  fetchingCursorData ==> preparingStatement
  fetchingCursorData ==> executingStatement
  fetchingCursorData ==> fetchingCursorData

  end
  auth ==> idle
  startup  == channel active ==> auth
  
  closed([closed])
  startup & idle & active
  active ==> closed
-->
