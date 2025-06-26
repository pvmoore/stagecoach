module stagecoach.ast.EnumMember;

import stagecoach.all;

/**
 * EnumMember
 *      Expression
 */
final class EnumMember : Expression {
    string name;

    // Node
    override NodeKind nodeKind() { return NodeKind.ENUM_MEMBER; }
    override bool isResolved() { return hasInitialiser() && value().isResolved(); }

    // Statement
    override Type getType() { return parent.as!Enum; }

    // Expression
    override int precedence() { return Precedence.LOWEST; }

    Expression value() { return first().as!Expression; }

    bool hasInitialiser() { return hasChildren(); }

    Enum getEnum() { return parent.as!Enum; }

    override string toString() {
        return "EnumMember %s".format(name);
    }
}
