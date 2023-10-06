#if compiler(>=5.9) && $AttachedMacros

@attached(member, names: arbitrary)
macro StateMachineStateConditions() = #externalMacro(module: "MySQLNIOCoreMacros", type: "StateMachineStateConditions")

#endif

