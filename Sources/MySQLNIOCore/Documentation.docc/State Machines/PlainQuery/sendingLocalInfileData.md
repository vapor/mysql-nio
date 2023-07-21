# ``MySQLNIOCore/MySQLChannel/Request/PlainQueryStateMachine/State/sendingLocalInfileData``

May span an arbitrary number of packets and is the only instance of a valid empty packet in the protocol aside from a fragment terminator.
            
### Transitions

- ``sendingLocalInfileData``
- ``awaitingResultsetStart``
- ``done(result:)``
