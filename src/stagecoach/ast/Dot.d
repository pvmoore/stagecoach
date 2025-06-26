module stagecoach.ast.Dot;

import stagecoach.all;

/**
 * Dot
 *     Expression   (Struct container)
 *     Expression   (Identifier member)
 */
final class Dot : Expression {
public:
    // Node
    override NodeKind nodeKind() { return NodeKind.DOT; }
    override bool isResolved() { return container().isResolved() && member().isResolved(); }

    // Statement
    override Type getType() { return member().getType(); }

    // Expression
    override int precedence() { return Precedence.DOT; }

    Expression container() { return first().as!Expression; }
    Expression member() { return last().as!Expression; }

    override string toString() {
        return "Dot";
    }
}
