# ``MySQLNIOCore/MySQLBuiltinAuthHandlers/CachingSHA2/State``

This state machine is responsible for the handling of authentication with the `caching_sha256_password` overall operation of a MySQL connection, starting with the initial handshake. It delegates most behaviors to various other purpose-specific state machines as appropriate. 

## State Diagram

![State diagram](https://mermaid.ink/svg/pako:eNqNUstOwzAQ_JXFUpUipQg4BhWJh7jwuJQb5rDYm8ZqbAd7Q6mq_DtOWkHLQ-LmndnZsXZnLZTXJAoxGq3BOMMFrKUDyErv-AatqVdZAZn1zscGFWX5wHJFlq5ms547Ij2nCVdGLRzFOHE-WKxz-I4PL1hD5OAXNFkazVUBJ807HBjb-MDo-Ay6rUNZ-6WqMHC2_VHCKrb1Hb5QHRNYYh0p3zINam3cPMGnxz3USddBNxpJ9zkHHi97BpdoOLU-eKdo_LRXPh_2HQ3GuPRBz8jx-Gm32vA_psB0ClI47yZkG159DpAiMecQqd9k5IuWqz-0v-p2nXvd7pxeFlul0l7_1StFiaYmDeNIqg10-E-PL51x-8pAry1FpiQNbxRuadXrf6K_2IhcWEoZMTrlbritFEOgpCjSU1OJbc1SpBumVmzZz1ZOiYJDS7loG41M1wbnAa0oNjEQpA37cL_J8hDp7gM9TvwF)
<!--
%%{ init: {
  'fontFamily': 'monospace',
  'themeCSS': '.edge-thickness-normal, .edge-thickness-thick { stroke-width: 1px !important; }',
  'flowchart': {'htmlLabels': false, 'padding': 20}
} }%%
flowchart TB
  awaitingNonce([awaitingNonce])
  passwordSent([passwordSent])
  
  awaitingNonce == "non-empty password" ==> sentFastAuth
  awaitingNonce == "empty password" ==> passwordSent
  sentFastAuth == success ==> passwordSent
  sentFastAuth == "failed (secure)" ==> passwordSent
  sentFastAuth == "failed (insecure)" ==> requestedServerKey
  requestedServerKey ==> passwordSent
-->
