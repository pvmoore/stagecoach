module stagecoach.ast.Call;

import stagecoach.all;

/**
 * Call
 *     { Expression }  arguments
 */
public:
final class Call : Expression {
    // static state
    string name;

    // dynamic state
    TargetOfCall target;
    CallResolveHistory resolveHistory;    // Populated during the resolve phase 

    // Node
    override NodeKind nodeKind() { return NodeKind.CALL; }
    override bool isResolved() { return target.isResolved(); }

    // Statement
    override Type getType() { return target.getType(); } 

    // Expression
    override int precedence() { return Precedence.CALL; }

    Expression[] arguments() { return children.map!(v=>v.as!Expression).array; }
    Type[] argumentTypes() { return arguments().map!(a => a.getType()).array; }

    override string toString() {
        return "%s() %s".format(name, target);
    }
}

Call makeCall(string name, Expression[] arguments) {
    auto c = makeNode!Call(0);
    c.target.call = c;
    c.name = name;
    c.addAll(arguments);
    return c;
}
