module stagecoach.ast.types.Function;

import stagecoach.all;

/**
 * Function
 *      Type        returnType      (1 required)
 *      { Variable }  parameters    (0 to n)
 *      { Statement } body          (0 to n)
 */
final class Function : Type {
public:
    // static state
    string name;                // This may be null if this is a function pointer
    string alias_;              // The name to use internally if specified via #(name) attribute
    bool isExtern;              // true if this is an extern function (assume C if no ABI attribute is specified)
    uint numParams;
    bool isMain;                // true if this is the main/winmain of the program
    bool hasVarargParam;        // true if this function has a vararg parameter
    string callingConvention;   // eg. "Win64". null means use the default calling convention
    bool isPublic;              // 

    // dynamic state
    bool isExternallyReferenced;    // true if this function is referenced from another Module
                                    // which means it will need to have external linkage
    LLVMTypeRef llvmType;                                     
    LLVMValueRef[string] llvmValueByModule;

    // Node
    override NodeKind nodeKind() { return NodeKind.FUNCTION; }
    override bool isResolved() { assert(returnType()); return returnType().isResolved() && paramTypes().areResolved(); }
    
    // Statement

    // Type
    override TypeKind typeKind() { return TypeKind.FUNCTION; }
    override bool exactlyMatches(Type other) { 
        if(Function o = other.as!Function) {
            // Ignore the name here
            return returnType().exactlyMatches(o.returnType()) && .exactlyMatches(paramTypes(), o.paramTypes());
        }
        return false; 
    }
    override bool canImplicitlyCastTo(Type other) {
        if(Function o = other.as!Function) {
            // For now we only allow implicit cast if the types exactly match
            if(!returnType().exactlyMatches(o.returnType())) return false;
            if(!.exactlyMatches(paramTypes(), o.paramTypes())) return false;
            return true;
        }
        if(PointerType o = other.as!PointerType) {
            // Allow Function ptr -> void*
            return o.valueType().isVoidValue();
        }
        return false;
    }

    string getName() { return alias_ ? alias_ : name; }

    override string shortName() { return "fn(%s)->%s".format(paramTypes().shortName(), returnType().shortName()); }
    override string mangledName() { return "%s(%s)".format(name, paramTypes().map!(v=>v.mangledName()).join(",")); }

    Type returnType() { assert(hasChildren()); return first().as!Statement.getType(); }
    Variable[] params() { return children[1..1+numParams].map!(v=>v.as!Variable).array; }
    Statement[] bodyStatements() { return children[1+numParams..$].map!(v=>v.as!Statement).array; }

    string[] paramNames() { return children[1..1+numParams].map!(v=>v.as!Variable.name).array; }
    Type[] paramTypes() { return children[1..1+numParams].map!(v=>v.as!Variable.getType()).array; }

    override string toString() { 
        string[] info;
        if(name) info ~= "'%s'".format(name);
        if(alias_) info ~= "alias '%s'".format(alias_);
        if(isPublic) info ~= "public";
        if(isMain) info ~= "isMain";
        if(hasVarargParam) info ~= "varargs";
        if(isExtern) info ~= "extern %s".format(callingConvention);
        info  ~= "%s param%s".format(numParams, numParams == 1 ? "" : "s");
                       
        return "Function [%s]*".format(info.join(", ")); 
    }
private:
}

//──────────────────────────────────────────────────────────────────────────────────────────────────

Function makeExternFunctionDeclaration(string name, Type returnType, Variable[] params, string callingConv = "C") {
    auto f = makeNode!Function(0);
    f.isExtern = true;
    f.name = name;
    f.hasVarargParam = params.any!(v=>v.getType().typeKind() == TypeKind.C_VARARGS);
    f.numParams = params.length.as!uint;
    f.callingConvention = callingConv;

    f.add(returnType);
    f.addAll(params);
    return f;
}
