module stagecoach.ast.types.Struct;

import stagecoach.all;

/**
 * Struct
 *      { Variable }  members
 */
final class Struct : Type {
public:
    // static state
    string name;            // The name if this is a named struct, otherwise null
    bool isPacked;          // true if this struct is packed (no padding between members)
    bool isPublic;

    // dynamic state
    LLVMTypeRef llvmType;   // Populated during the generation phase

    // Node
    override NodeKind nodeKind() { return NodeKind.STRUCT; }
    override bool isResolved() { 
        if(!resolved) {
            resolved = members().areResolved(); 
            if(resolved) allChildrenAreResolved();
        }
        return resolved;
    }

    // Type
    override TypeKind typeKind() { return TypeKind.STRUCT; }

    override bool exactlyMatches(Type other) {
        if(Struct o = other.extract!Struct) {
            return .exactlyMatches(memberTypes(), o.memberTypes());
        }
        return false;
    }
    override bool canImplicitlyCastTo(Type other) {
        if(Struct o = other.extract!Struct) {
            // Named Structs must have the same name
            if(name && name!= o.name) return false;

            return .exactlyMatches(memberTypes(), o.memberTypes());
        }
        return false;
    }
    override string shortName() { 
        if(name) return name;
        return "struct{%s}".format(memberTypes.map!(v => v.shortName()).join(", "));
    }
    override string mangledName() { return "S%s".format(name); }

    Variable[] members() { return children.map!(v=>v.as!Variable).array; }
    Type[] memberTypes() { return children.map!(v=>v.as!Statement.getType()).array; }

    bool isNamed() { return name !is null; }

    int getMemberIndex(Variable member) {
        assert(resolved);
        return members().indexOf(member);
    }
    int getMemberIndex(string name) {
        assert(resolved);
        foreach(i, m; members()) if(m.name == name) return i.as!int;
        return -1;
    }
    Variable getMemberByIndex(uint index) {
        assert(resolved);
        return children[index].as!Variable;
    }
    Variable getMemberByName(string name) {
        assert(resolved);
        auto index = getMemberIndex(name);
        return index == -1 ? null : getMemberByIndex(index.as!uint);
    }

    uint getSize() {
        assert(resolved);
        return size;
    }
    uint getAlignment() {
        assert(resolved);
        return alignment;
    }
    uint getOffsetOfMember(uint memberIndex) {
        int offset  = 0;
        int largest = 1;
        Type[] types = memberTypes();

        foreach(i, t; types) {
            int align_    = t.alignment();
            int and       = (align_-1);
            int newOffset = (offset + and) & ~and;
            
            if(i == memberIndex) return newOffset;

            offset = newOffset + t.size();

            largest = maxOf(align_, largest);
        }

        /// The final size must be a multiple of the largest alignment
        offset = (offset + (largest-1)) & ~(largest-1);

        return offset;
    }

    override string toString() {
        string[] info;
        if(isNamed()) info ~= "'%s'".format(name);
        if(isPublic) info ~= "public";
        if(isPacked) info ~= "packed";
        if(resolved) {
            info ~= "size %s".format(getSize());
            info ~= "align %s".format(getAlignment());
        } else {
            info ~= "UNRESOLVED";
        }
        return "Struct [%s]".format(info.join(", "));
    }
private:
    bool resolved;
    uint size;
    uint alignment;

    void allChildrenAreResolved() {

        if(isPacked) {
            this.size = members().map!(m => m.getType().size()).sum;
        } else {
            this.size = calculateAggregateSize();
        }

        foreach(m; members()) {
            this.alignment = maxOf(alignment, m.getType().alignment());
        }
        // Minimum alignment is 1
        this.alignment = maxOf(alignment, 1);
    }

    int calculateAggregateSize() {
        return getOffsetOfMember(uint.max);
    }
}

