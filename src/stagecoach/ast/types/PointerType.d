module stagecoach.ast.types.PointerType;

import stagecoach.all;

/**
 * PointerType
 *      [ Expression ]        valueType (optional) (should resolve to a Type)
 */
final class PointerType : Type {
public:
    // Node
    override NodeKind nodeKind() { return NodeKind.POINTER_TYPE; }
    override bool isResolved() { return valueExpr().isResolved(); }

    // Statement

    // Type
    override TypeKind typeKind() { return TypeKind.POINTER; }

    override bool exactlyMatches(Type other) {
        if(PointerType o = other.extract!PointerType) {
            return valueType().exactlyMatches(o.valueType());
        }
        return false;
    }
    override bool canImplicitlyCastTo(Type other) {
        if(PointerType o = other.extract!PointerType) {
            // Left and right are both pointers

            // Allow void* to cast to any other pointer type
            if(valueType().isVoidValue()) return true;

            // Allow any pointer to cast to void* 
            if(other.isVoidValue()) return true;

            return valueType().canImplicitlyCastTo(o.valueType());
        }
        if(Function f = other.as!Function) {
            // Allow void* -> function ptr 
            return this.valueType().isVoidValue();
        }
        // Allow pointer to be cast to bool
        if(other.isBool()) return true;
        return false;
    }
    override string shortName() { return "%s*".format(valueType().shortName()); }
    override string mangledName() { return "P%s".format(valueType().mangledName()); }

    Expression valueExpr() { return hasChildren() ? first().as!Expression : type; }

    Type valueType() { return valueExpr().as!Type; }

    override string toString() {
        if(isResolved()) return "%s*".format(valueType());
        return "ptr";
    }
private:
    Type type;      // The type of the value this pointer points to (if numChildren() == 0)
}

PointerType makePointerType(Type elementType) {
    auto p = makeNode!PointerType(0);
    p.type = elementType;
    return p;
}

PointerType makeBytePointerType() {
    auto p = makeNode!PointerType(0);
    p.type = makeByteType();
    return p;
}

PointerType makeFunctionPtrType(Function f) {
    auto p = makeNode!PointerType(0);
    p.type = f;
    return p;
}

PointerType makePointerTypeWithChild(Expression elementType) {
    auto p = makeNode!PointerType(0);
    p.add(elementType);
    return p;
}
