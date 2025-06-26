module stagecoach.generating.generate;

import stagecoach.all;

void generateAddressOf(AddressOf n, GenerateState state) {
    state.generate(n.expr());

    // Type type = n.getType();//.as!PointerType.valueType();
    // auto indices = [LLVMConstInt(LLVMInt32TypeInContext(state.context), 0, 0)];
    // state.rhs = LLVMBuildInBoundsGEP2(state.builder, state.getLLVMType(type), state.lhs, indices.ptr, 1, "address_of");

    state.rhs = state.lhs;
    assert(state.rhs.isPointer());
}
void generateValueOf(ValueOf n, GenerateState state) {
    state.generate(n.expr());
    
    assert(state.rhs.isPointer());
    state.lhs = LLVMBuildInBoundsGEP2(state.builder, state.getLLVMType(n.getType()), state.rhs, [LLVMConstInt(state.INT32_TYPE, 0, 0)].ptr, 1, "address");
    //state.lhs = state.rhs;
    
    state.rhs = LLVMBuildLoad2(state.builder, state.getLLVMType(n.getType()), state.rhs, "value_of");
}

void generateAs(As n, GenerateState state) {
    state.generate(n.expr());
    state.castType(state.rhs, n.expr().getType(), n.getType());
}

void generateDot(Dot n, GenerateState state) {
    state.generate(n.container());
    if(n.container().getType().isPointer()) {
        state.lhs = state.rhs;
    }

    //state.rhs = LLVMBuildLoad2(state.builder, state.getLLVMType(n.container().getType()), state.lhs, "dot");

    state.generate(n.member());
}

void generateEnumMember(EnumMember n, GenerateState state) {
    state.generate(n.value());
}

void generateNodeRef(NodeRef n, GenerateState state) {
    state.generate(n.node);
}

void generateNull(Null n, GenerateState state) {
    state.rhs = LLVMConstNull(state.getLLVMType(n.getType()));
}

void generateNumber(Number n, GenerateState state) {
    //log("generate Number %s", n.stringValue);
    LLVMTypeRef numType = state.getLLVMType(n.getType());
    LLVMValueRef value;
    switch(n.getType().typeKind()) {
        case TypeKind.BOOL:   
        case TypeKind.BYTE:   value = LLVMConstInt(numType, n.value.byteValue, 1); break;
        case TypeKind.SHORT:  value = LLVMConstInt(numType, n.value.shortValue, 1); break;
        case TypeKind.INT:    value = LLVMConstInt(numType, n.value.intValue, 1); break;
        case TypeKind.LONG:   value = LLVMConstInt(numType, n.value.longValue, 1); break;
        case TypeKind.FLOAT:  value = LLVMConstReal(numType, n.value.floatValue); break;
        case TypeKind.DOUBLE: value = LLVMConstReal(numType, n.value.doubleValue); break;
        default: throwIf(true, "We shouldn't get here. type is %s", n.getType().typeKind());
    }
    state.rhs = value;
}

void generateParens(Parens n, GenerateState state) {
    state.generate(n.expr());
}

void generateReturn(Return n, GenerateState state) {
    if(n.hasChildren()) {
        state.generate(n.first());
        state.castType(state.rhs, n.expr().getType(), n.func().returnType);
        LLVMValueRef ret = LLVMBuildRet(state.builder, state.rhs);
    } else {
        LLVMBuildRetVoid(state.builder);
    }
}

void generateStringLiteral(StringLiteral n, GenerateState state) {
    assert(n.llvmValue);
    state.rhs = n.llvmValue;
}

void generateUnary(Unary n, GenerateState state) {
    // Generate the expression
    state.generate(n.expr());
    
    if(n.op is Operator.BOOL_NOT) {
        state.rhs = LLVMBuildNot(state.builder, state.rhs, "not");
    } else if(n.op is Operator.BIT_NOT) {
        state.rhs = LLVMBuildNot(state.builder, state.rhs, "not");
    } else if(n.op is Operator.NEG) {
        //auto op = n.getType().isReal() ? LLVMOpcode.LLVMFSub : LLVMOpcode.LLVMSub;
        //rhs = builder.binop(op, n.expr().getType().zeroValue, rhs);

        // LLVMOpcode.LLVMFNeg

        state.rhs = LLVMBuildNeg(state.builder, state.rhs, "neg");
    }
}


