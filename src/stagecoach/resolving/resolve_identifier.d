module stagecoach.resolving.resolve_identifier;

import stagecoach.all;

void resolveIdentifier(Identifier n, ResolveState state) {

    if(n.isStartOfChain()) {
        // This must be a Variable or Function within the same Module

        if(n.hasAncestor(NodeKind.FUNCTION)) {
            // Look for a local Variable with the same name (must occur earlier in the function)
            Node node = n;
            while(true) {
                node = node.prev(true);
                if(node is null) break;
                if(node.isA!Function) break;

                if(Variable v = node.as!Variable) {
                    if(v.name == n.name) {
                        n.target = TargetOfIdentifier.make(n, v);
                        break;
                    }
                }
            }
        }

        // Look for a global Variable with the same name
        Module mod = state.mod;
        foreach(k; mod.children) {
            if(Variable v = k.as!Variable) {
                if(v.name == n.name) {
                    n.target = TargetOfIdentifier.make(n, v);
                    break;
                }
            } else if(Function f = k.as!Function) {
                if(f.name == n.name) {
                    n.target = TargetOfIdentifier.make(n, f);
                    break;
                }
            } else if(Enum e = k.as!Enum) {
                if(!e.isUnqualified) continue; 

                // Search through unqualified enums
                if(EnumMember member = e.getMemberByName(n.name)) {
                    // rewrite to EnumMember
                    rewriteToNodeRef(state, n, member);
                    return;
                }
            }
        }
    } else {
        // Resolve from the previous link in the chain
        auto prev = n.prevLink(); assert(prev);
        if(!prev.isResolved()) return;
        
        Type prevType = prev.getType();

        // Enum.A
        if(prevType.isEnum() && prev.isA!Type) {
            if(EnumMember member = prevType.extract!Enum.getMemberByName(n.name)) {
                rewriteToNodeRef(state, n.parent.as!Dot, member);
            }
            return;
        }

        if(Enum e = prevType.extract!Enum) {
            prevType = e.elementType();
        }



        // Struct.member
        if(prevType.isStruct() && prev.isA!Type) {
            if(Variable v = prevType.extract!Struct.getMemberByName(n.name)) {
                // Rewrite if the Variable is const except if:
                //  - this Struct.member is inside an offsetOf expression --> ::offsetOf(Struct.member)
                bool doRewrite = v.isConst && v.hasInitialiser();
                if(Builtin b = n.getAncestor!Builtin) {
                    if(b.name == "@offsetOf") doRewrite = false;
                }
                if(doRewrite) {
                    // Replace the Dot parent with the variable initialiser
                    rewriteToNodeRef(state, n.parent.as!Dot, v.initialiser());
                    return;
                }
            }
        }

        // id1.id2 (this is id2)
        if(Identifier id = prev.as!Identifier) {

            // if 'id1' is an identifier that is an Enum then switch to the enum element type 
            if(Enum e = prevType.extract!Enum) {
                prevType = e.elementType(); 
            }
        }

        if(Struct st = prevType.extract!Struct) {
            if(Variable v = st.getMemberByName(n.name)) {
                n.target = TargetOfIdentifier.make(n, v);
            }
        } else if(ModuleRef mr = prev.as!ModuleRef) {
            Module mod = mr.mod;
            foreach(k; mod.children) {
                if(Enum e = k.as!Enum) {
                    if(!e.isUnqualified) continue;

                    // Search through unqualified enums
                    if(EnumMember member = e.getMemberByName(n.name)) {
                        // rewrite Dot to EnumMember
                        rewriteToNodeRef(state, n.parent.as!Dot, member);
                        return;
                    }
                } 
            }

            // Do we want to allow access to external module variables in general? We already allow for
            // function ptrs. We probably should for consistency.

            todo("[%s] resolveIdentifier: ModuleRef functions and variables", state.mod.name);

        // } else if(Enum e = prevType.extract!Enum) {
        //     consoleLog("prevType is enum : %s member = %s", e.name, e.getMemberByName(n.name));

        //     // Replace the parent Dot with the enum member ref
        //     if(EnumMember member = e.getMemberByName(n.name)) {
        //         rewriteToNodeRef(state, n.parent.as!Dot, member);
        //         return;
        //     }
        } else {
            todo("[%s] resolveIdentifier: prev is a %s", state.mod.name, prev.nodeKind());
        }
    } 

    n.resolveEvaluated = true;      
}
