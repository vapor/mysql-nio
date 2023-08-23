# ``MySQLNIOCore/MySQLChannel/Request/PlainQueryStateMachine/State``

This state machine is responsible for the handling of plain text queries.

## State Diagram

![State diagram](https://mermaid.ink/svg/pako:eNqVVE1v2zAM_SusgMAZ5rTbjh66w7r11GJAslu8A2fRsVB9GBINrzD83yfZxZC6SYtdbIl8j3yk8TyIykkShVitBlBWcQFDaQGy2lm-RaP0Y1ZAZpx1ocWKsnzKckOGbna7lLskeaANN6p6sBTCxjpvUOewjE8nGCCwdw-06ZXkpoCP7R-4UKZ1ntHyZxifOtTa9VWDnmOLIWvY6Dv8TTrEa406UA5Zi1Iqe4iRTx_G0o4wrlal_UeEn19TJexRcYRtKXSaA_GOY3K9Px3_9S5xpLO03qfnfK9RaZLr_fyeY-drw_U1lOL7j1t4D8Z5KkWMfDkDfr1M5TrLz9g3TnfG3hOjRMa3RMz8_sqBiYwnIZ4w7W3r-vA6P42QCGkRbyC32wk5L-gY-1zvrCotBTTVvNjM-dlOVbFR1XGVM2O9pL4Ue0RNAO_6UxUXqP_6xAvucrPL9EKhyIWh6Colo1Mnf5ZismApiniUVGPsV4poggjFjt3u0VaiYN9RLro2Tk7fFB48GlHM9hEkFTt_P7t_-gmMfwFPW2bB)
<!--
%%{ init: {
  'fontFamily': 'monospace',
  'themeCSS': '.edge-thickness-normal, .edge-thickness-thick { stroke-width: 1px !important; }',
  'flowchart': {'htmlLabels': false, 'padding': 20}
} }%%
flowchart TB
  awaitingResultsetStart([awaitingResultsetStart])
  done([done])
  failed([failed])
  
  awaitingResultsetStart == "EOF + more" ==> awaitingResultsetStart
  awaitingResultsetStart == count ==> awaitingColumnMetadata
  awaitingResultsetStart == "count w/o meta" ==> readingRows
  awaitingResultsetStart == EOF ==> done
  awaitingResultsetStart == ERR ==> failed
  awaitingColumnMetadata == "more left" ==> awaitingColumnMetadata
  awaitingColumnMetadata == "none left" ==> readingRows
  awaitingColumnMetadata == ERR ==> failed
  readingRows == row ==> readingRows
  readingRows == "EOF + more" ==> awaitingResultsetStart
  readingRows == EOF ==> done
  readingRows == ERR ==> failed
-->
![State diagram for LOCAL INFILE](https://mermaid.ink/svg/pako:eNqFU01r3DAQ_StTweINtZemR5fk0KaBkJTAbm7rHibWeC2iD0eaZROM_3slOx9Q1snFkua9eXpjnnpRO0miFItFD8oqLqGvLEDWOMuXaJR-zkrIjLMudFhTlo8ot2To12aTsBXJHRXcqvrBUgiFdd6gzuH_-riDHgJ790DFQUluSzjtnuCLMp3zjJZ_wPByQ6PdoW7Rc7yiz1o2-gbvSYd4bFAHyiHrUEpld7Hy_dtQ2QGGxaKyb41w9zMp4QEVR9qawl5zIN5wBJfb4_W_J6lHOkvLbfpO5waVJrncTutUm9eGszOoxO_bS_gKxnmqRKycz5A_lkkiqTdZ-YS5Xo_MyeIH3GIVzSnbRBp4eozmVsU5BLLpX964GvXVCF4gY5I5jkwyt9fvIyaV-RHnVaJGan2dcJ6YJkzM1wlFLgzFqCkZ4zuGthJjLitRxq2kBqOJSsRkRCru2W2ebS1K9nvKxb6TyHShcOfRiHLKlCCp2Pk_05MYX8bwDwGvE-g)
<!--
%%{ init: {
  'fontFamily': 'monospace',
  'themeCSS': '.edge-thickness-normal, .edge-thickness-thick { stroke-width: 1px !important; }',
  'flowchart': {'htmlLabels': false, 'padding': 20}
} }%%
flowchart TB
  awaitingResultsetStart([awaitingResultsetStart])
  done([done])
  failed([failed])
  
  awaitingResultsetStart == "EOF + more" ==> awaitingResultsetStart
  awaitingResultsetStart == EOF ==> done
  awaitingResultsetStart == ERR ==> failed
  awaitingResultsetStart -. "infile req" .-> sendingLocalInfileData
  sendingLocalInfileData -. "OK + more" .-> awaitingResultsetStart
  sendingLocalInfileData -. OK .-> done
  sendingLocalInfileData -. ERR .-> failed
-->

