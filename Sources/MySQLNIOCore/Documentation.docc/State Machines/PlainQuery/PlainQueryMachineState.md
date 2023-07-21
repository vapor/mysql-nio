# ``MySQLNIOCore/MySQLChannel/Request/PlainQueryStateMachine/State``

This state machine is responsible for the handling of plain text queries.

## State Diagram

![State diagram](https://mermaid.ink/svg/pako:eNqVU01v2zAM_SuchsAtlnQfhxwcdIe162nDgKS3uAfFpmOh-jAkGl5g-L-Psr2hyZp2u1jSI9_TE012IncFilTMZh0oqyiFLrMASeks3Umj9CFJITHOulDLHJP5EKUKDcbAToYj7GazifAVFntcUKXyR4shjDvoIJB3j7hoVUFVCh_rn_BGmdp5kpZW0MOVZTfgMSdOLpXWKbwty3I17BeOHSg6MHE1KXF4uVwyc_JQatfmlfTEJrqkIqO_yR3qwMdS6oBzSGpZFMruGfn0oc9sD_1sltk_RLj_EpUKZ_FiG78Pl_Ecmt3ey7oC6-iWUdjCQ8Q5U0W7ytmJCSBbqYivWGNoNAWkDbHwxfZ5fNQ_x4Lra8jE1x938A6M85gJRj6fSX5NKHeNpSP-jdONsd-RZCFJvm5kVGjfOzDMmcx4lLGia9eGY4Vj9VEhPgI0lnTykpecPKdj4094ovOXiSdAZHjX_lPefxUbbRGX8xWLWlEiNlLMPLnsNPy7uUYf6_VkYAyLuTDojVQFj-swpJkYZi4TKW8LLCXfngnuaU6VDbnNweYiJd_gXDQ11w5vleQ2NiIdpqH_BW-qWpM)
<!--
%%{ init: {
  'fontFamily': 'monospace',
  'theme': 'base',
  'themeCSS': '.edge-thickness-thick { stroke-width: 1px !important; } .node rect { fill: #fff; fill-opacity: 1; stroke: #666; }',
  'flowchart': {'htmlLabels': false, 'padding': 20}
} }%%
flowchart TB
  done([done])
  subgraph notDone [ ]
    direction TB
    awaitingResultsetStart([awaitingResultsetStart])
    awaitingResultsetStart == "EOF + more" ==> awaitingResultsetStart
    awaitingResultsetStart == count ==> awaitingColumnMetadata
    awaitingResultsetStart == "count w/o meta" ==> readingRows
    awaitingColumnMetadata == "more left" ==> awaitingColumnMetadata
    awaitingColumnMetadata == "none left" ==> readingRows
    readingRows == row ==> readingRows
    readingRows == "EOF + more" ==> awaitingResultsetStart
  end
  awaitingResultsetStart == EOF ==> done
  readingRows == EOF ==> done
  notDone == "ERR" ==> done
-->
![State diagram for LOCAL INFILE](https://mermaid.ink/svg/pako:eNqFU01v2zAM_SucisAdGgfbDjk4aA9bVmBYgQJJb3EPjE3HQvXhWTSywPB_H-WkGwo02cE2Rb73-CRTvSp8SSpTk0kP2mnOoM8dQFJ5x_dotTkkGSTWOx8aLCiZjlWuyVIsbDG8yX1br2N6RuWOUq518eIohGMEPQRu_Qule11yncHn5jd80LbxLaPjBQwwc-IGWipYwJU2JoOrqqoWY5x6caD5IMTFSUnK8_lcmCcPlfH7osaWxUSf1GzNA27JBFlWaAJNIWmwLLXbSebLpyF3AwyTSe7-EuHpa1QqvaPrTXw_f4zr-IRuu2uxqcF5XkoFNvAc84LW0bL27sQGwD1qljYrCp3hQLxmEb_evJ8_9jjHgttbyNX3x3u4AetbypVk7s6A_ycUZSI7bu0iNp1JU-3k4OMP-SVNZ-kdBHLx9B58gebHWFwi41Ho_dpR6PHnP_NR55L58zqiEsmv3gUXPxc2u1q92ex55Yh8lQY1VZZai7qUizFeh1yN052rTMKSKpRGuZLpESh27NcHV6iM246mqmtKZFpqlGGxKhvnbvgDXvclsQœ)
<!--
%%{ init: {
  'fontFamily': 'monospace',
  'theme': 'base',
  'themeCSS': '.edge-thickness-thick { stroke-width: 1px !important; } .node rect { fill: #fff; fill-opacity: 1; stroke: #666; }',
  'flowchart': {'htmlLabels': false, 'padding': 20}
} }%%
flowchart TB
  done([done])
  subgraph notDone [ ]
    direction TB
    awaitingResultsetStart([awaitingResultsetStart])
    awaitingResultsetStart == "EOF + more" ==> awaitingResultsetStart
    awaitingResultsetStart == EOF ==> done
    awaitingResultsetStart -. "infile req" .-> sendingLocalInfileData
    sendingLocalInfileData -. "OK + more" .-> awaitingResultsetStart
    sendingLocalInfileData -. OK .-> done
  end
  awaitingResultsetStart == ERR ==> done
  sendingLocalInfileData -. ERR .-> done  
-->

