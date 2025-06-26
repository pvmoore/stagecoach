module stagecoach.resolving.resolve_call;

import stagecoach.all;

void resolveCall(Call n, ResolveState state) {
    //state.log("  Resolving call %s",  n.name);

    // todo - We can use the call.resolveHistory here to see if it is worth re-resolving.
    //        For now we will just repeat the work
    n.resolveHistory.reset();

    if(Expression prev = n.prevLink()) {
        if(ModuleRef mr = prev.as!ModuleRef) {
            collectModuleRefNameCandidates(n, mr, state);
        } else {
            // We should just take the prev Expression and rewrite this call to call(prev, args...)
            todo("Rewrite UFCS call");
        }
    } else {
        collectNameCandidates(n, state);
        if(n.resolveHistory.nameCandidates.length == 0) return noMatch(n);
        if(n.resolveHistory.nameCandidates.length == 1) return match(n, n.resolveHistory.nameCandidates[0]);
    }

    //if(state.mod.name=="tests/imports/unqualified" && n.name=="print")
    //state.log("resolveCall(%s) name candidates: %s", n.name, n.resolveHistory.nameCandidates);

    // We have 1 or more candidates in the list
    if(!selectParamNumCandidates(n, n.resolveHistory.nameCandidates)) {
        // Exit here if the Target candidates are not sufficiently resolved
        return;
    }
    if(n.resolveHistory.paramNumCandidates.length == 0) return noMatch(n);
    if(n.resolveHistory.paramNumCandidates.length == 1) return match(n, n.resolveHistory.paramNumCandidates[0]);

    // We still have multiple candidates. Check the argument types. We need the arguments to be resolved now
    if(!n.arguments().areResolved()) return;

    //if(state.mod.name=="tests/imports/unqualified" && n.name=="print")
    //state.log("resolveCall(%s) paramNumCandidates: %s", n.name, n.resolveHistory.paramNumCandidates);

    if(!selectParamTypeCandidates(n, n.resolveHistory.paramNumCandidates)) {
        // Exit here if the Target candidates are not sufficiently resolved
        return;
    }

    if(state.mod.name=="tests/imports/unqualified" && n.name=="print") {
        state.mod.log(" call: %s(%s)", n.name, n.argumentTypes().shortName());
        state.mod.log("   exactTypeCandidates: %s", n.resolveHistory.exactTypeCandidates);
        state.mod.log("   implicitTypeCandidates: %s", n.resolveHistory.implicitTypeCandidates);
    }

    n.resolveHistory.exactTypeCandidates = deDuplicateExternCFunctions(n, n.resolveHistory.exactTypeCandidates);
    n.resolveHistory.implicitTypeCandidates = deDuplicateExternCFunctions(n, n.resolveHistory.implicitTypeCandidates);

    // A single exact match 
    if(n.resolveHistory.exactTypeCandidates.length == 1) {
        return match(n, n.resolveHistory.exactTypeCandidates[0]);
    }
    // If we have multiple exact matches then this is an error
    if(n.resolveHistory.exactTypeCandidates.length > 1) {
        resolutionError(n, ErrorKind.CALL_AMBIGUOUS_FUNCTION);
        return;
    }
    // We don't have any exact matches
    assert(n.resolveHistory.exactTypeCandidates.length == 0);

    // A single implicit match
    if(n.resolveHistory.implicitTypeCandidates.length == 1) {
        return match(n, n.resolveHistory.implicitTypeCandidates[0]);
    }

    // No matches at all
    if(n.resolveHistory.implicitTypeCandidates.length == 0) {
        return noMatch(n);
    }

    // We have multiple implicit matches
    assert(n.resolveHistory.implicitTypeCandidates.length > 1);

    // Try to resolve by converting integer arg -> integer param to exact matches
    auto toc = selectByIntegerPromotion(n, n.resolveHistory.implicitTypeCandidates);
    if(toc != NO_TARGET_OF_CALL) {
        return match(n, toc);
    }

    resolutionError(n, ErrorKind.CALL_AMBIGUOUS_FUNCTION);
}

struct CallResolveHistory {
    Call call;
    TargetOfCall match;
    TargetOfCall[] nameCandidates;              // All Functions and Variables with the same name
    
    TargetOfCall[] paramNumCandidates;          // Subset of above where num params is correct
    TargetOfCall[] exactTypeCandidates;         // Subset of above where the argument types exactly match the parameter types
    TargetOfCall[] implicitTypeCandidates;      // Subset of above where the argument types can be implicitly cast to the parameter types
    TargetOfCall[] duplicates;                  // Subset of exact/implicit where the function is an extern(C) and is defined multiple times

    void reset() {
        match = NO_TARGET_OF_CALL;
        nameCandidates.length = 0;
        paramNumCandidates.length = 0;
        exactTypeCandidates.length = 0;
        implicitTypeCandidates.length = 0;
        duplicates.length = 0;
    }
    string toString() {
        return "CallResolveInfo {\n" ~
            "  match             %s\n" ~
            "  nameCandidates    %s\n" ~
            "  paramNumCandidates  %s\n" ~
            "  exactTypeCandidates %s\n" ~
            "  implicitTypeCandidates %s\n" ~
            "  duplicates        %s\n}"
            .format(match != NO_TARGET_OF_CALL ? match.toString() : "none", 
                nameCandidates, paramNumCandidates, exactTypeCandidates, implicitTypeCandidates, duplicates);
    }
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

void noMatch(Call n) {
    n.resolveHistory.match = NO_TARGET_OF_CALL;
}
void match(Call n, TargetOfCall t) {
    n.resolveHistory.match = t;
    n.target = t;
}

/**
 * Collect all Functions that have the same name as the Call.
 * At this point we don't care whether the number or type of arguments match.
 */
void collectNameCandidates(Call n, ResolveState state) {
    // Look for a function with the same name in the current Module
    Module mod = state.mod;
    foreach(k; mod.children) {
        if(Function f = k.as!Function) {
            if(f.getName() == n.name) {
                n.resolveHistory.nameCandidates ~= TargetOfCall.make(n, f);
            }
        } else if(Variable v = k.as!Variable) {
            if(v.name == n.name) {
                n.resolveHistory.nameCandidates ~= TargetOfCall.make(n, v);
            }
        }
    }

    // Look for a variable with the same name in the current Function
    Node nd = n.prev(false);
    while(nd) {
        if(Variable v = nd.as!Variable) {
            if(v.name == n.name) {
                n.resolveHistory.nameCandidates ~= TargetOfCall.make(n, v);
            }
        }
        nd = nd.prev(false);
    }

    // Look for a function with the same name in the imported Modules
    foreach(imp; mod.childrenOfType!Import()) {

        // Only check unaliased imports
        if(imp.name !is null) continue;

        // Only look at public Functions and Variables
        foreach(k; imp.fromModule.children) {
            if(Function f = k.as!Function) {
                if(f.isPublic && f.getName() == n.name) {
                    n.resolveHistory.nameCandidates ~= TargetOfCall.make(n, f);
                }
            } else if(Variable v = k.as!Variable) {
                if(v.isPublic && v.name == n.name) {
                    n.resolveHistory.nameCandidates ~= TargetOfCall.make(n, v);
                }
            }
        }
    }
}

/**
 * Collect all Functions that have the same name as the Call in the referenced Module.
 */
void collectModuleRefNameCandidates(Call n, ModuleRef mr, ResolveState state) {
    // Only look at public Functions and Variables
    foreach(k; mr.mod.children) {
        if(Function f = k.as!Function) {
            if(f.isPublic && f.getName() == n.name) {
                n.resolveHistory.nameCandidates ~= TargetOfCall.make(n, f);
            }
        } else if(Variable v = k.as!Variable) {
            if(v.isPublic && v.name == n.name) {
                n.resolveHistory.nameCandidates ~= TargetOfCall.make(n, v);
            }
        }
    }
}

/** 
 * Remove any duplicate extern(C) Functions from the candidates list.
 */
TargetOfCall[] deDuplicateExternCFunctions(Call n, TargetOfCall[] candidates) {
    TargetOfCall[] subset;
    Module mod = n.getModule();
    foreach(c; candidates) {
        bool foundDupe = false;
        foreach(s; subset) {
            if(!c.isExtern() || !s.isExtern()) continue;

            // Both of these are extern which means they must both be Functions

            Function f = c.func;
            Function sf = s.func;
            assert(f);
            assert(sf);

            if(f.exactlyMatches(sf)) {
                foundDupe = true; 
                log(mod, "  Removing duplicate function %s", f.name);
                n.resolveHistory.duplicates ~= TargetOfCall.make(n, f);
                break;
            }
        }
        if(!foundDupe) {
            subset ~= c;
        }
    }
    return subset;
}

/**
 * Collect all Functions that have the same name and number of parameters as the Call.
 * At this point we don't care whether the argument types match the parameter types.
 */
bool selectParamNumCandidates(Call n, TargetOfCall[] candidates) {
    auto callNumArgs = n.arguments().length;
    foreach(c; candidates) {

        // Bail out here. We need this Variable Type to be resolved to get the params
        if(c.isVariable() && !c.isResolved()) return false;

        int numParams = c.numParams();
        bool hasVarargParam = c.hasVarargParam();

        if(numParams == callNumArgs) {
            n.resolveHistory.paramNumCandidates ~= c;
        } else if(hasVarargParam) {
            assert(numParams > 0);
            // One of the Function parameters will be the ... vararg so the call must have at least 
            // one less argument than the function has parameters
            if(callNumArgs >= numParams-1)  {
                n.resolveHistory.paramNumCandidates ~= c;
            }
        }
    }
    return true;
}

bool selectParamTypeCandidates(Call n, TargetOfCall[] candidates) {
    Type[] argTypes = n.argumentTypes();
    foreach(c; candidates) {

        // We need the Target to be resolved now
        if(!c.isResolved()) return false;

        Type[] paramTypes = c.paramTypes();
        int numParams = c.numParams();
        bool hasVarargParam = c.hasVarargParam();

        if(hasVarargParam) {
            // Vararg Function candidate
            assert(numParams >= paramTypes.length-1);

            bool exact = true;
            bool implicit = true;

            foreach(i; 0..paramTypes.length-1) {
                if(!argTypes[i].exactlyMatches(paramTypes[i])) {
                    exact = false;
                }  
                if(!argTypes[i].canImplicitlyCastTo(paramTypes[i])) {
                    implicit = false;
                }
                if(!exact && !implicit) break;
            }

            if(exact) {
                n.resolveHistory.exactTypeCandidates ~= c;
            } else if(implicit) {
                n.resolveHistory.implicitTypeCandidates ~= c;
            }
        } else {
            // Normal, non-vararg Function candidate
            assert(argTypes.length == paramTypes.length);

            // Check for exact matches first
            if(exactlyMatches(argTypes, paramTypes)) {
                n.resolveHistory.exactTypeCandidates ~= c;
            } else 

            // Check that the argument types can be implicitly cast to the parameter types
            if(argTypes.canImplicitlyCastTo(paramTypes)) {
                n.resolveHistory.implicitTypeCandidates ~= c;
            }
        }
    }
    return true;
}

/**
 * Select the best match of any integer arguments.
 *  eg. byte matches short,int or long in preference to float or double
 *
 * print(10 as byte) implicitly matches:
 *  - print(int)
 *  - print(float)
 *  but we should pick the int candidate because the argument is integer.
 */
TargetOfCall selectByIntegerPromotion(Call n, TargetOfCall[] candidates) {
    TargetOfCall[] intPromotionCandidates;
    Type[] argTypes = n.argumentTypes();
    foreach(c; candidates) {
        // Ignore vararg candidates for now
        if(c.hasVarargParam()) continue;

        Type[] paramTypes = c.paramTypes();
        int numParams = c.numParams();
        assert(argTypes.length == paramTypes.length);
        bool exact = true;
        int numIntPromotions = 0;
    
        foreach(i; 0.. numParams) {
            Type arg = argTypes[i];
            Type param = paramTypes[i];

            if(!arg.exactlyMatches(param)) {
                // arg must implicitly match param here otherwise it would not be in the candidates list
                
                if(arg.isInteger() && param.isInteger()) {
                    // arg size must be less than param size otherwise it would 
                    // be exact or the candidate would not be in the list
                    assert(arg.size() < param.size());

                    // Treat this as an exact match
                    numIntPromotions++;
                    continue;
                }
                exact = false;
                break;
            }
        }

        if(exact) {    
            intPromotionCandidates ~= c;
        }
    }

    if(intPromotionCandidates.length > 0) {
        //log("  selectByIntegerPromotion: %s", intPromotionCandidates);
    }

    if(intPromotionCandidates.length == 1) {
        return intPromotionCandidates[0];
    }

    return NO_TARGET_OF_CALL;
}
