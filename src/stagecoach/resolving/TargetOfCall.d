module stagecoach.resolving.TargetOfCall;

import stagecoach.all;

__gshared TargetOfCall NO_TARGET_OF_CALL = TargetOfCall(null, null, null);

/**
 * This is the target of a Call.
 */
struct TargetOfCall {
    Call call;          // The Call that this is the target of
    Variable var;
    Function func;

    static TargetOfCall make(Call c, Function f) {
        return TargetOfCall(c, null, f);
    }
    static TargetOfCall make(Call c, Variable v) {
        return TargetOfCall(c, v, null);
    }

    bool isVariable() { return var !is null; }
    bool isFunction() { return func !is null; }

    Statement getNode() { return isVariable() ? var : isFunction() ? func : null; }

    Module getClientModule() { return call.getModule(); }
    Module getTargetModule() { return isResolved() ? getNode().getModule() : null; }

    Type getType() { return isVariable() ? var.getType().extract!Function.returnType() : isFunction() ? func.returnType() : makeUnknownType(); }

    bool isResolved() { return isVariable() ? var.isResolved() : isFunction() ? func.isResolved() : false; }

    bool isMember() { return isVariable() ? var.isMember() : false; }

    bool isRemote() { return isResolved() && getTargetModule() !is getClientModule(); }

    LLVMValueRef getLLVMValue() { 
        Module mod = getClientModule();
        return isVariable() ? var.llvmValueByModule[mod.name] : isFunction() ? func.llvmValueByModule[mod.name] : null; 
    } 

    Type[] paramTypes() { 
        if(isFunction()) {
            return isFunction() ? func.paramTypes() : null; 
        }
        if(Function f = var.getType().extract!Function) {
            return f.paramTypes();
        }
        return null;
    }
    Type returnType() {
        if(isFunction()) {
            return func.returnType;
        }
        if(Function f = var.getType().extract!Function) {
            return f.returnType;
        }
        return null;
    }
    int numParams() {
        if(isFunction()) {
            return func.numParams;
        }
        if(Function f = var.getType().extract!Function) {
            return f.numParams;
        }
        return 0;
    }
    bool hasVarargParam() {
        if(isFunction()) { 
            return func.hasVarargParam; 
        }
        if(Function f = var.getType().extract!Function) {
            return f.hasVarargParam;
        }
        return false;
    }
    bool isExtern() {
        if(isFunction()) {
            return func.isExtern;
        }
        return false;
    }

    string toString() {
        if(!isResolved()) return "Target(UNRESOLVED)";

        string r = isRemote() ? "[%s].".format(getTargetModule().name) : "";
        if(isVariable()) return "Target{%s%s(%s)}".format(r, var.name, paramTypes().shortName());
        return "Target{%s%s}".format(r, func.shortName());
    }
}
