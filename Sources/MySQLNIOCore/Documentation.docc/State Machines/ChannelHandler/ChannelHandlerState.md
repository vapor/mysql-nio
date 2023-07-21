# ``MySQLNIOCore/MySQLChannel/Handler/State``

This state machine is responsible for the overall operation of a MySQL connection, starting with the initial handshake

## State Diagram

![State diagram](https://mermaid.ink/svg/pako:eNqdVFGP0zAM_iuhaOxO2k7Awx46DgnudDxwEnC7t3YPWeKu0dIkJC7bNO2_42QZaDoNaURV6ny2P7uO3V0hrISiLAaDHVNGYcl2tWFs2FiDD7xTejss2bCzxgbHBQxHSYstdBAVCx5OsLvZLMI3IJcwxlaJlYEQDhLbsYDermC8VhLbkr1zG_ZKdc565AanbM9uDGXDPAgk40ZpXbLXTdNMkzy2lIHCLTlOMxOpJ5MJeeYcGm3XouUeh_k7CGux0498AToQ2HAdYJQ1jkupzJLg928jtK_Nnu0Hg9r84WHPn6Mm9Iul565lvMf24C1VTFNZk00Y42uukPi-eID4Juj2lj0_zhgYvtAg6fiRZaMH60nzBFxu_-VtbCJIK3ofrT5RHk_gdHZ-SXoMHZC-Ioc-4_wCTpHrIj7HddYdjIyv0yJRXX7BuTKt7ao6Un37Oj8JQTr2hi0D0u7dT9pdkmEjaG9Erj0ZVEvAyDBDjiqgEmF-EQWpKt8bQxTfNVfmRw9-exkFgZXz4LjPeVD_G5xfQkHHCjYgevxvChKqBlC0xHDX-2D9PUd-AUW6wXR_V1Xqlt7Nr2MH0AAYAzpf56EF6OqjKvRC0FwnTEkN7EO0t13HTW61vz7iqhLaBpDz69oUo6ID33El6Z-TJrQu0o-jLkoSJTS811gXNIlkSuHsbGtEUaLvYVT0TlKJ7hWnPuuKMg3z_jeAdYhx)
<!--
%%{ init: {
  'fontFamily': 'monospace',
  'theme': 'base',
  'themeCSS': '.edge-thickness-thick { stroke-width: 1px !important; } .node rect { fill: #fff; fill-opacity: 1; stroke: #666; }',
  'flowchart': {
    'htmlLabels': false,
    'padding': 20
  }
} }%%
flowchart TB
  subgraph auth
    direction TB
    awaitingGreeting   == TLS enabled ==> waitingForTLSReady
    awaitingGreeting   == no TLS      ==> awaitingAuthReply
    waitingForTLSReady == TLS started ==> awaitingAuthReply
    awaitingAuthReply  == " "         ==> awaitingAuthReply
  end
  
  subgraph active
    direction TB
    wok[awaitingOK]         ==> wok & gst & rpq & pst & exc & fch
    gst[gettingStatistics]  ==> wok & gst & rpq & pst & exc & fch
    rpq[runningPlainQuery]  ==> wok & gst & rpq & pst & exc & fch
    pst[preparingStatement] ==> wok & gst & rpq & pst & exc & fch
    exc[executingStatement] ==> wok & gst & rpq & pst & exc & fch
    fch[fetchingCursorData] ==> wok & gst & rpq & pst & exc & fch
  end

  s([startup]) == channel active ==> auth == success ==> idle <== command ==> active ==> c([closed])
-->
