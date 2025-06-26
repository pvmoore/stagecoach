module stagecoach.resolving.TargetOfIdentifier;

import stagecoach.all;

__gshared TargetOfIdentifier NO_TARGET_OF_IDENTIFIER = TargetOfIdentifier(null, null, null);

/**
 * This is the target of an Identifier.
 */
struct TargetOfIdentifier {
    Identifier identifier;  // The Identifier that this is the target of
    Variable var;
    Function func;

    static TargetOfIdentifier make(Identifier i, Variable v) {
        return TargetOfIdentifier(i, v, null);
    }
    static TargetOfIdentifier make(Identifier i, Function f) {
        return TargetOfIdentifier(i, null, f);
    }

    bool isVariable() { return var !is null; }
    bool isFunction() { return func !is null; }

    Statement getNode() { return isVariable() ? var : isFunction() ? func.getType() : null; }

    Module getClientModule() { return identifier.getModule(); }
    Module getTargetModule() { return isResolved() ? getNode().getModule() : null; }

    Type getType() { return isVariable() ? var.getType() : isFunction() ? func : makeUnknownType(); }

    bool isResolved() { return isVariable() ? var.isResolved() : isFunction() ? func.isResolved() : false; }

    bool isMember() { return isVariable() ? var.isMember() : false; }

    bool isRemote() { return isResolved() && getTargetModule() !is getClientModule(); }

    bool isConst() { return isVariable() ? var.isConst : true; }
    bool isPublic() { return isVariable() ? var.isPublic : isFunction() ? func.isPublic : false; }

    LLVMValueRef getLLVMValue() {
        Module mod = getClientModule();
        return isVariable() ? var.llvmValueByModule[mod.name] : isFunction() ? func.llvmValueByModule[mod.name] : null; 
    } 

    string toString() {
        if(!isResolved()) return "Target(UNRESOLVED)";
        string r = isRemote() ? "%s.".format(getTargetModule().name) : "";
        if(isVariable()) return "Target(%s%s)".format(r, var);
        return "Target(fn %s%s)".format(r, func.name);
    }
}

