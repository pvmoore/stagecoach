module stagecoach.ast.Is;

import stagecoach.all;

/**
 * Is
 *     Expression
 *     Expression
 *     
 * Type       is TypeExpr
 * Identifier is Type
 * Identifier is Identifier
 */
final class Is : Expression {
public:
    bool negate;

    this() {
        _type = makeBoolType();
    }

    // Node
    override NodeKind nodeKind() { return NodeKind.IS; }
    override bool isResolved() { return resolveEvaluated && left().isResolved() && right().isResolved(); }

    // Statement
    override Type getType() { return _type; }

    // Expression
    override int precedence() { return Precedence.IS; }

    Expression left() { return first().as!Expression; }
    Expression right() { return last().as!Expression; }

    Type leftType() { return left().getType(); }
    Type rightType() { return right().getType(); }

    Type oppositeSideType(Node side) {
        return side is left() ? rightType() : leftType();
    }

    override string toString() {
        return "is%s".format(negate ? " not" : "");
    }
private:
    Type _type;
}
