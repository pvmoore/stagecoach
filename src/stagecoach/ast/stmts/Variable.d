module stagecoach.ast.stmts.Variable;

import stagecoach.all;

/**
 * Variable
 *      Expression      type (Should resolve to a Type)
 *      [ Expression ]  initialiser
 */
final class Variable : Statement {
public:
    // static state
    string name;
    VariableKind vkind;
    bool isPublic;
    bool isConst;

    // dynamic state
    bool isExternallyReferenced;            // true if this variable is referenced from another Module
                                            // which means it will need to have external linkage
    LLVMValueRef[string] llvmValueByModule; // populated during the generation phase

    // Node
    override NodeKind nodeKind() { return NodeKind.VARIABLE; }
    override bool isResolved() { return getType().isResolved(); }

    // Statement
    override Type getType() { throwIf(first() is null, ""); return first().as!Expression.getType(); }

    Expression initialiser() { assert(hasInitialiser()); return children[1].as!Expression; }
    bool hasInitialiser() { return numChildren() > 1; }

    bool isLocal() { return vkind == VariableKind.LOCAL; }
    bool isGlobal() { return vkind == VariableKind.GLOBAL; }
    bool isParameter() { return vkind == VariableKind.PARAMETER; }
    bool isMember() { return vkind == VariableKind.MEMBER; }

    override string toString() {
        string[] info;
        if(name) info ~= "'%s'".format(name);
        if(isPublic) info ~= "public";
        if(isConst) info ~= "const";
        return "Variable [%s]".format(info.join(", "));
    }
}

enum VariableKind {
    LOCAL,
    GLOBAL,
    PARAMETER,
    MEMBER
}

Variable makeVariable(string name, Type type, VariableKind vkind) {
    auto v = makeNode!Variable(0);
    v.name = name;
    v.vkind = vkind;
    v.add(type);
    return v;
} 
