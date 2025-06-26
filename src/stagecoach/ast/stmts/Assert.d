module stagecoach.ast.stmts.Assert;

import stagecoach.all;

/**
 * Assert
 *     Expression
 */
final class Assert : Statement {
public:
    this() {
        _type = makeVoidType();
    }

    // Node
    override NodeKind nodeKind() { return NodeKind.ASSERT; }
    override bool isResolved() { return false; }

    // Statement
    override Type getType() { return _type; }

    Expression expr() { return first().as!Expression; }

    override string toString() {
        string[] info;
        return "assert %s".format(info);
    }
private:
    Type _type;
}

