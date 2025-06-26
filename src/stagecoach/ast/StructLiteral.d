module stagecoach.ast.StructLiteral;

import stagecoach.all;

/**
 * StructLiteral
 *     { Expression }  members
 */
final class StructLiteral : Expression {
public:
    string[] names;

    this() {
        _type = makeUnknownType();
    }

    // Node
    override NodeKind nodeKind() { return NodeKind.STRUCT_LITERAL; }
    override bool isResolved() { return _type.isResolved(); }

    // Statement
    override Type getType() { return _type; }

    // Expression
    override int precedence() { return Precedence.LOWEST; }

    Expression[] members() { return children.map!(v=>v.as!Expression).array; }

    uint numMembers() { return names.length.as!uint; }
    bool hasNamedArguments() { return names.any!(v=>v !is null); }
    bool hasUnnamedArguments() { return names.any!(v=>v is null); }

    Expression getMember(uint index) { return children[index].as!Expression; }
    Expression getMember(string name) {
        int index = names.indexOf(name);
        if(index == -1) return null;
        return getMember(index.as!uint);
    }

    Struct getStruct() { return _type.extract!Struct; }

    void setType(Type type) { this._type = type; }

    override string toString() {
        string[] info;
        info ~= _type.isResolved() ? "%s".format(_type) : "UNRESOLVED";
        info ~= hasNamedArguments() ? "named" : "unnamed";
        info ~= "%s".format(_type.shortName());
        return "{struct} %s".format(info.join(", "));
    }
private:
    Type _type;
}

