module stagecoach.ast.Null;

import stagecoach.all;

/**
 * Null
 */
final class Null : Expression {
public:
    this() {
        _type = makeUnknownType();
    }

    // Node
    override NodeKind nodeKind() { return NodeKind.NULL; }
    override bool isResolved() { return _type.isResolved(); }

    // Statement
    override Type getType() { return _type; }

    // Expression
    override int precedence() { return Precedence.LOWEST; }

    void setType(Type type) { this._type = type; }
    
    override string toString() {
        return "null %s".format(_type);
    }
private:
    Type _type;
}

Null makeNull(Type type) {
    auto n = makeNode!Null(0);
    n.setType(type);
    return n;
}
