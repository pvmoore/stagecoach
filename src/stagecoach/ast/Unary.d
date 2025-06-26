module stagecoach.ast.Unary;

import stagecoach.all;

/**
 * Unary
 *     Expression
 */
final class Unary : Expression {
public:
    Operator op;

    // Node
    override NodeKind nodeKind() { return NodeKind.UNARY; }
    override bool isResolved() { return getType().isResolved(); }

    // Statement
    override Type getType() { return expr().getType(); }

    // Expression
    override int precedence() { return precedenceOf(op); } 

    Expression expr() { return first().as!Expression; }

    override string toString() {
        return "Unary (%s)".format(op);
    }
}
