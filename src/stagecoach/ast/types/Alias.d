module stagecoach.ast.types.Alias;

import stagecoach.all;

/**
 * Alias
 *     Type
 */
final class Alias : Type {
public:
    string name;
    bool isPublic;

    // Node
    override NodeKind nodeKind() { return NodeKind.ALIAS; }
    override bool isResolved() { return aliasedType().isResolved(); }

    // Type
    override TypeKind typeKind() { return aliasedType().typeKind(); }

    override bool exactlyMatches(Type other) {
        return aliasedType.exactlyMatches(other);
    }
    override bool canImplicitlyCastTo(Type other) {
        return aliasedType.canImplicitlyCastTo(other);
    }

    Type aliasedType() { return first().as!Type; }

    override string shortName() { return name; }
    override string mangledName() { return aliasedType().mangledName(); }

    override string toString() {
        string[] info;
        if(name) info ~= "'%s'".format(name);
        if(isPublic) info ~= "public";
        return "Alias [%s]".format(info.join(", "));
    }
}
