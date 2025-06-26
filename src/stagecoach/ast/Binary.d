module stagecoach.ast.Binary;

import stagecoach.all;

/**
 * Binary
 *     Expression
 *     Expression
 */
final class Binary : Expression {
public:
    Operator op;
    Type type;

    this() {
        type = makeUnknownType();
    }

    // Node
    override NodeKind nodeKind() { return NodeKind.BINARY; }
    override bool isResolved() { assert(type); return type.isResolved(); }

    // Statement
    override Type getType() { return type; }

    // Expression
    override int precedence() { return precedenceOf(op); } 

    Expression left() { return first().as!Expression; }
    Expression right() { return last().as!Expression; }

    Type leftType() { return left().getType(); }
    Type rightType() { return right().getType(); }

    Type oppositeSideType(Node side) {
        return side is left() ? rightType() : leftType();
    }
    bool isOnLeft(Node n) { return n.hasAncestor(left()); }
    bool isOnRight(Node n) { return n.hasAncestor(right()); }

    override string toString() {
        return "Binary (%s) %s".format(op.stringOf().replace("%", "%%"), type);
    }
}

Binary makeBinary(Operator op, Expression left, Expression right, Type type = null) {
    auto b = makeNode!Binary(0);
    b.op = op;
    b.type = type ? type : makeUnknownType();
    b.add(left);
    b.add(right);
    return b;
}
