module stagecoach.ast.ArrayLiteral;

import stagecoach.all;

/**
 * ArrayLiteral
 *     { Expression }  elements
 */
final class ArrayLiteral : Expression {
public:
    this() {
        type = makeUnknownType();
    }

    // Node
    override NodeKind nodeKind() { return NodeKind.ARRAY_LITERAL; }
    override bool isResolved() { return type.isResolved(); }

    // Statement
    override Type getType() { return type; }

    // Expression
    override int precedence() { return Precedence.LOWEST; }

    Expression[] elements() { return children.map!(v=>v.as!Expression).array; }

    Type elementType() { assert(isResolved()); return type.as!ArrayType.elementType(); }

    void setType(Type type) { this.type = type; }

    override string toString() {
        string t = type.isResolved() ? "%s".format(type) : "UNRESOLVED";
        return "[array literal] %s".format(t);
    }
private:
    Type type;
}
