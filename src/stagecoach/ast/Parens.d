module stagecoach.ast.Parens;

import stagecoach.all;

/**
 * Parens
 *     Expression    
 */
final class Parens : Expression {
public:

    // Node
    override NodeKind nodeKind() { return NodeKind.PARENS; }
    override bool isResolved() { return expr().isResolved(); }

    // Statement
    override Type getType() { return expr().getType(); }

    // Expression
    override int precedence() { return Precedence.LOWEST; }

    Expression expr() { return first().as!Expression; }
    
    override string toString() {
        return "()";
    }
}
