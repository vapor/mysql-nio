# Protocol Data Types

A discussion of the encodings, formats, and flags used by MySQL's wire protocol for transmiting
individual "data" values in both directions

## Overview

The protocol defines two "main" encoding forms for values, whether inputs (parameters) or outputs
(fields):

- term `text`:
  
  - All non-`NULL` values are stored as plain text. Integers, decimals, and temporal types are converted to strings with `binary` collation.

. The "text" encoding transmits all non-`NULL` values in textual form, and uses a sentinel
byte to indicate `NULL`. The "binary" encoding transmits non-`NULL` integer, floating-point, fixed-
point, and temporal values in a "compact" format and retains the textual encoding for all other non-
`NULL` values. A packed bit array is used as a map of `NULL` value flags. 

### Section header

