module stagecoach.generating.generate_index;

import stagecoach.all;

void generateIndex(Index n, GenerateState state) {
    // Get the index value
    state.generate(n.index());
    state.castType(state.rhs, n.index().getType(), makeIntType());
    LLVMValueRef indexValue = state.rhs;

    // Get the array/pointer
    state.generate(n.expr());

    LLVMValueRef[] indices = [indexValue];
    LLVMTypeRef elementType = state.getLLVMType(n.getType());

    if(n.isArrayIndex()) {
        state.lhs = LLVMBuildInBoundsGEP2(state.builder, elementType, state.lhs, indices.ptr, 1, "element_ptr");

    } else if(n.isPointerIndex()) {
        state.lhs = LLVMBuildInBoundsGEP2(state.builder, elementType, state.rhs, indices.ptr, 1, "element_ptr");

    } else {
        todo("handle non array and ptr index");
    }

    state.rhs = LLVMBuildLoad2(state.builder, elementType, state.lhs, "lvalue");
}

