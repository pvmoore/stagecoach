module stagecoach.ast.types.TypeRef;

import stagecoach.all;

/**
 * TypeRef
 *
 * Used to reference another Type in the AST.
 */
final class TypeRef : Type {
public:
    string name;
    Module fromModule;      // The module we are referencing from if a module alias was used eg. "mod.Type"
    Type type;

    this() {
        type = makeUnknownType();
    }

    // Node
    override NodeKind nodeKind() { return NodeKind.TYPE_REF; }
    override bool isResolved() { return type.isResolved(); }

    // Type
    override TypeKind typeKind() { return type.typeKind(); }

    override bool exactlyMatches(Type other) {
        return type.exactlyMatches(other);
    }
    override bool canImplicitlyCastTo(Type other) {
        return type.canImplicitlyCastTo(other);
    }
    override string shortName() { return type.shortName(); }
    override string mangledName() { return type.mangledName(); }

    override string toString() {
        string m;
        if(fromModule) {
            m ~= "module: %s, ".format(fromModule.name);
        }
        string n = name ? "'%s', ".format(name) : "";
        string t = type.isResolved() ? "%s".format(type.shortName()) : "UNRESOLVED";
        return "TypeRef %s%s%s".format(m, n, t);
    }
}

TypeRef makeTypeRef(string name) {
    auto t = makeNode!TypeRef(0);
    t.name = name;
    return t;
}

TypeRef makeTypeRef(Type type) {
    auto t = makeNode!TypeRef(0);
    t.type = type;
    return t;
}
