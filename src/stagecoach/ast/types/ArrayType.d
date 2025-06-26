module stagecoach.ast.types.ArrayType;

import stagecoach.all;

/**
 *  ArrayType
 *      Type        elementType
 *      Number      numElements 
 */
final class ArrayType : Type {
public:
    LLVMTypeRef llvmType;

    // Node
    override NodeKind nodeKind() { return NodeKind.ARRAY_TYPE; }
    override bool isResolved() { 
        return elementType.isResolved() && 
               numElementsExpr().isResolved() &&
               numElementsExpr().extractNumber() !is null; 
    }

    // Statement

    // Type
    override TypeKind typeKind() { return TypeKind.ARRAY; }

    override bool exactlyMatches(Type other) {
        assert(isResolved() && other.isResolved());
        if(ArrayType o = other.as!ArrayType) {
            return numElements == o.numElements && elementType.exactlyMatches(o.elementType);
        }
        return false;
    }
    override bool canImplicitlyCastTo(Type other) {
        if(ArrayType o = other.as!ArrayType) {
            // The length and element types must match
            return numElements() == o.numElements() && elementType.exactlyMatches(o.elementType);
        }
        return false;
    }

    override string shortName() { return "%s[]".format(elementType().shortName()); }

    override string mangledName() { return "A%s[%s]".format(elementType().mangledName(), numElements()); }

    Type elementType() { 
        return first().as!Type; 
    }
    Expression numElementsExpr() { 
        return last().as!Expression; 
    }
    int numElements() { 
        assert(isResolved(), "Don't call this until the ArrayType is resolved"); 
        assert(numElementsExpr().extractNumber() !is null, "numElement is not a Number");
        return numElementsExpr().extractNumber().value.intValue; 
    }

    override string toString() {
        string numElementsStr = numElementsExpr().isA!Number ? numElementsExpr().as!Number.stringValue : "UNRESOLVED";
        return "[%s x %s]".format(elementType(), numElementsStr);
    }
}

ArrayType makeArrayType(Type elementType, int numElements) { 
    auto a =  makeNode!ArrayType(0);
    a.add(elementType);
    a.add(makeIntNumber(numElements));
    return a; 
}
