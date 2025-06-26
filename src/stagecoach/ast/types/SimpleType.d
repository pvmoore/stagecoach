module stagecoach.ast.types.SimpleType;

import stagecoach.all;

final class SimpleType : Type {
public:
    // Node
    override NodeKind nodeKind() { return NodeKind.BASIC_TYPE; }
    override bool isResolved() { return tkind != TypeKind.UNKNOWN; }

    // Type
    override TypeKind typeKind() { return tkind; }

    override bool exactlyMatches(Type other) {
        if(other.isPointer()) return false;
        if(SimpleType o = other.extract!SimpleType()) {
            return tkind == o.tkind;
        }
        return false;
    }
    override bool canImplicitlyCastTo(Type other) {
        if(other.isPointer()) return false;
        if(SimpleType o = other.extract!SimpleType()) {

            // Allow any type to be cast to bool
            if(other.isBool()) return true;

            if(this.isReal()) {
                if(other.isReal()) return other.typeKind() >= this.typeKind();
            } else if(this.isInteger()) {
                if(other.isReal()) return true;
                if(other.isInteger()) return other.size() >= this.size();
            } else {
                return tkind == o.tkind;
            }
        }
        return false;
    }
    override string shortName() { return this.toString(); }

    override string mangledName() {
        switch(tkind) {
            case TypeKind.BOOL: return "B";
            case TypeKind.BYTE: return "b";
            case TypeKind.SHORT: return "s";
            case TypeKind.INT: return "i";
            case TypeKind.LONG: return "l";
            case TypeKind.FLOAT: return "f";
            case TypeKind.DOUBLE: return "d";
            case TypeKind.VOID: return "v";
            case TypeKind.C_VARARGS: return "V";
            default: assert(false); 
        }
    }

    void setTypeKind(TypeKind tk) { tkind = tk; } 

    override string toString() {
        string s;
        switch(tkind) {
            case TypeKind.UNKNOWN: s = "unknown"; break;
            case TypeKind.VOID: s = "void"; break;
            case TypeKind.BOOL: s = "bool"; break;
            case TypeKind.BYTE: s = "byte"; break;
            case TypeKind.SHORT: s = "short"; break;
            case TypeKind.INT: s = "int"; break;
            case TypeKind.LONG: s = "long"; break;
            case TypeKind.FLOAT: s = "float"; break;
            case TypeKind.DOUBLE: s = "double"; break;
            case TypeKind.C_VARARGS: s = "..."; break;
            default: assert(false); 
        } 
        return "%s".format(s);
    }
private:
    TypeKind tkind = TypeKind.UNKNOWN;
}

Type makeBoolType() { return makeSimpleType(TypeKind.BOOL); }
Type makeByteType() { return makeSimpleType(TypeKind.BYTE); }
Type makeShortType() { return makeSimpleType(TypeKind.SHORT); }
Type makeIntType() { return makeSimpleType(TypeKind.INT); }
Type makeLongType() { return makeSimpleType(TypeKind.LONG); }
Type makeFloatType() { return makeSimpleType(TypeKind.FLOAT); }
Type makeDoubleType() { return makeSimpleType(TypeKind.DOUBLE); }
Type makeVoidType() { return makeSimpleType(TypeKind.VOID); }
Type makeUnknownType() { return makeSimpleType(TypeKind.UNKNOWN); }

Type makeSimpleType(TypeKind tk) { 
    auto t = makeNode!SimpleType(0);
    t.tkind = tk;
    return t; 
}
