# ``MySQLNIOCore/MySQLChannel/Request/PlainQueryStateMachine/State/awaitingResultsetStart``

The first reply to a `COM_QUERY` may be one of an OK packet, an ERR packet, a LOCAL INFILE request, or a result set column count. Disambiguating these four possibilities can be unintuitive; see the ``MySQLNIOCore/Request/PlainQueryStateMachine/handlePacketRead(_:)`` method for details.

### Transitions

- _initial_
- ``awaitingResultsetStart``
- ``sendingLocalInfileData``
- ``awaitingColumnMetadata(columnsRemaining:)``
- ``readingRows``
- ``done(result:)``
