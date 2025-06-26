module stagecoach.ast.types.Enum;

import stagecoach.all;

/**
 * Enum
 *    Type        element type
 *    { EnumMember }  members
 */
final class Enum : Type {
public:
    string name;
    bool isPublic;
    bool isUnqualified;

    // Node
    override NodeKind nodeKind() { return NodeKind.ENUM; }
    override bool isResolved() { return resolveEvaluated && elementType().isResolved() && allMembersHaveInitialisers(); }

    // Type
    override TypeKind typeKind() { return TypeKind.ENUM; }

    override bool exactlyMatches(Type other) {
        if(Enum o = other.extract!Enum) {
            return name == o.name;
        }
        return false;
    }
    override bool canImplicitlyCastTo(Type other) {
        if(Enum o = other.extract!Enum) {
            return name == o.name;
        }
        return false;
    }

    Type elementType() { return first().as!Type; }
    EnumMember[] members() { return children[1..$].map!(v=>v.as!EnumMember).array; }
    int numMembers() { return numChildren()-1; }

    bool allMembersHaveInitialisers() {
        return members().all!(m=>m.hasInitialiser());
    }

    EnumMember getMemberByName(string name) {
        return children[1..$].map!(it=>it.as!EnumMember)
                             .find!(it=>it.name == name)
                             .frontOrElse!EnumMember(null);
    }
    EnumMember getMemberByIndex(uint index) {
        return children[1+index].as!EnumMember;
    }

    override string shortName() { return name; }

    override string mangledName() { return "E%s".format(name); }

    override string toString() {
        string[] info;
        if(name) info ~= "'%s'".format(name);
        if(isPublic) info ~= "public";
        if(isUnqualified) info ~= "unqualified";
        if(!isResolved()) info ~= "UNRESOLVED";
        return "Enum [%s]".format(info.join(", "));
    } 
}

