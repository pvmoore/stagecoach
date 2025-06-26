module stagecoach.ast.types.Type;

import stagecoach.all;

abstract class Type : Expression {
public:
    // Statement
    override Type getType() { return this; }

    // Expression
    override int precedence() { return Precedence.LOWEST; }
    
    // Type
    abstract TypeKind typeKind();
    abstract bool exactlyMatches(Type);
    abstract bool canImplicitlyCastTo(Type);

    abstract string shortName();
    abstract string mangledName();
}

//──────────────────────────────────────────────────────────────────────────────────────────────────

T extract(T)(Type t) if(is(T : Type)) {
    if(T o = t.as!T) return o;
    if(TypeRef tr = t.as!TypeRef) return extract!T(tr.type);
    if(Alias a = t.as!Alias) return extract!T(a.aliasedType());
    if(PointerType pt = t.as!PointerType) return extract!T(pt.valueType());
    return null;
}

bool isVoidValue(Type t) { return t.typeKind() == TypeKind.VOID && !t.isPointer(); }
bool isInteger(Type t) { return t.typeKind() >= TypeKind.BYTE && t.typeKind() <= TypeKind.LONG; }
bool isReal(Type t) { return t.typeKind() == TypeKind.FLOAT || t.typeKind() == TypeKind.DOUBLE; }
bool isBool(Type t) { return t.typeKind() == TypeKind.BOOL; }
bool isPointer(Type t) { return t.typeKind() == TypeKind.POINTER || t.typeKind() == TypeKind.FUNCTION; }
bool isValue(Type t) { return !isPointer(t); }
bool isVararg(Type t) { return t.typeKind() == TypeKind.C_VARARGS; }

bool isFunction(Type t) { 
    return t.typeKind() == TypeKind.FUNCTION; 
}
bool isArrayType(Type t) { 
    return t.typeKind() == TypeKind.ARRAY; 
}
bool isStruct(Type t) { 
    return t.extract!Struct !is null; 
}
bool isAnonStruct(Type t) {
    if(Struct st = t.extract!Struct) return st.name is null;
    return false;
}
bool isEnum(Type t) { 
    return t.extract!Enum !is null; 
}

bool isPublic(Type t) {
    if(Struct st = t.extract!Struct) return st.isPublic;
    if(Enum en = t.extract!Enum) return en.isPublic;
    if(Alias al = t.extract!Alias) return al.isPublic;
    return true;
}

uint size(Type t) {
    final switch(t.typeKind()) {
        case TypeKind.ARRAY: {
            // todo - account for alignment here
            ArrayType at = t.extract!ArrayType;
            return at.numElements() * size(at.elementType());
        }
        case TypeKind.FUNCTION: 
            // todo - this is 8 if this is a function pointer, otherwise this might be an error
            return 8;
        case TypeKind.STRUCT:
            return t.extract!Struct.getSize();    
        case TypeKind.POINTER:
            return 8;
        case TypeKind.BOOL: 
        case TypeKind.BYTE: 
            return 1;
        case TypeKind.SHORT: 
            return 2;
        case TypeKind.INT: 
        case TypeKind.FLOAT: 
            return 4;
        case TypeKind.LONG: 
        case TypeKind.DOUBLE: 
            return 8;
        case TypeKind.ENUM:
            return size(t.extract!Enum.elementType());
        case TypeKind.VOID: 
        case TypeKind.UNKNOWN: 
        case TypeKind.C_VARARGS:
            throwIf(true, "size(%s) not supported", t.typeKind()); 
            assert(false);
    }
    assert(false);
}

uint alignment(Type t) {
    if(t.isPointer()) return 8;
    switch(t.typeKind()) {
        case TypeKind.BOOL: 
        case TypeKind.BYTE: 
            return 1;
        case TypeKind.SHORT: 
            return 2;
        case TypeKind.INT: 
        case TypeKind.FLOAT: 
            return 4;
        case TypeKind.LONG: 
        case TypeKind.DOUBLE: 
            return 8;
        case TypeKind.ARRAY:
            return alignment(t.extract!ArrayType.elementType());
        case TypeKind.STRUCT:
            return t.extract!Struct.getAlignment();
        case TypeKind.ENUM:
            return alignment(t.extract!Enum.elementType());
        default:
            throwIf(true, "alignment(%s) not supported", t.typeKind()); 
            assert(false);
    }
    assert(false);
}

/**
 * Return the largest type of a or b.
 * Return null if they are not compatible.
 */
Type selectCommonType(Type a, Type b) {
    if(a.isVoidValue() || b.isVoidValue()) return null;

    if(a.exactlyMatches(b)) return a;

    if(a.isPointer() || b.isPointer()) return null;

    if(a.isStruct() || b.isStruct()) {
        throwIf(true, "Handle Structs here");
        return null;
    }
    if(a.isArrayType() || b.isArrayType()) {
        throwIf(true, "Handle ArrayTypes here");
        return null;
    }
    
    if(a.isFunction() || b.isFunction()) {
        throwIf(true, "Handle Functions here");
        return null;
    }

    if(a.isReal() == b.isReal()) {
        return a.typeKind() > b.typeKind() ? a : b;
    }
    if(a.isReal()) return a;
    if(b.isReal()) return b;
    return a;
}

bool exactlyMatches(Type[] a, Type[] b) {
    if(a.length != b.length) return false;
    foreach(i, t; a) {
        if(!t.exactlyMatches(b[i])) return false;
    }
    return true;
}
bool canImplicitlyCastTo(Type[] a, Type[] b) {
    if(a.length != b.length) return false;
    foreach(i, t; a) {
        if(!t.canImplicitlyCastTo(b[i])) return false;
    }
    return true;
}
string shortName(Type[] t) {
    return t.map!(v=>v.shortName()).join(", ");
}
