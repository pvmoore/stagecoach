module stagecoach.generating.generate_array;

import stagecoach.all;

void generateArrayLiteral(ArrayLiteral n, GenerateState state) {

    // Generate the element values
    LLVMValueRef[] elements = n.elements().map!((e) {
        state.generate(e);
        state.castType(state.rhs, e.getType(), n.elementType());
        return state.rhs;
    }).array;


    // Create a local to hold the array literal
    LLVMValueRef arrayPtr = LLVMBuildAlloca(state.builder, state.getLLVMType(n.getType()), "array_literal_temp");

    // Store the elements into the temp array
    foreach(i, e; elements) {
        state.setArrayValue(arrayPtr, state.getLLVMType(n.elementType()), e, i.as!uint, "element[%s].ptr".format(i));
    }

    // Load the temp array value
    state.rhs = LLVMBuildLoad2(state.builder, state.getLLVMType(n.getType()), arrayPtr, "array_literal_value");
    state.lhs = arrayPtr;
}

void defaultInitialiseArray(ArrayType array, LLVMValueRef arrayPtr, GenerateState state) {
    Type elementType = array.elementType();
    LLVMTypeRef arrayTypeRef = state.getLLVMType(array);
    LLVMTypeRef elementTypeRef = state.getLLVMType(elementType);

    // Empty array. Nothing to do
    if(array.numElements() == 0) return;

    if(elementType.isPointer()) {
        LLVMBuildStore(state.builder, LLVMConstNull(arrayTypeRef), arrayPtr);
        return;
    }

    if(Enum e = elementType.extract!Enum) {
        // Initialise the first value
        EnumMember member = e.getMemberByIndex(0);
        state.generate(member);
        state.castType(state.rhs, member.getType(), e.elementType());
        LLVMBuildStore(state.builder, state.rhs, arrayPtr);

        // Propagate the value to all of the elements
        propagateArrayValue(array, arrayPtr, elementTypeRef, state);
        return;
    }
    if(Struct st = elementType.extract!Struct) {

        // Initialise the first value
        defaultInitialiseStruct(st, arrayPtr, state, false);

        // Propagate the value to all of the elements
        propagateArrayValue(array, arrayPtr, elementTypeRef, state);

        return;
    }

    // Zero initialise the array
    LLVMBuildStore(state.builder, LLVMConstNull(arrayTypeRef), arrayPtr);
}

/**
 * Generate a loop to copy the first element value to all of the other elements (if there is more than 1 element)
 */
void propagateArrayValue(ArrayType array, LLVMValueRef arrayPtr, LLVMTypeRef elementTypeRef, GenerateState state) {
    
    // Only 1 element. No need to copy anything 
    if(array.numElements() == 1) return;

    LLVMValueRef endCounterValue = state.createConstI32Value(array.numElements() - 1);
    LLVMValueRef srcValue = LLVMBuildLoad2(state.builder, elementTypeRef, arrayPtr, "array_init_src");

    LLVMBasicBlockRef loopBlock = state.createBlock("array_init_loop");
    LLVMBasicBlockRef startBlock = LLVMGetPreviousBasicBlock(loopBlock);
    LLVMBasicBlockRef endBlock = state.createBlock("array_init_end");

    LLVMBuildBr(state.builder, loopBlock);

    // loop:
    LLVMPositionBuilderAtEnd(state.builder, loopBlock);
    LLVMValueRef phi = LLVMBuildPhi(state.builder, state.INT32_TYPE, "counter_phi");
    
    LLVMValueRef counter = LLVMBuildAdd(state.builder, phi, state.createConstI32Value(1), "counter");
    LLVMAddIncoming(phi, [state.createConstI32Value(0), counter].ptr, [startBlock, loopBlock].ptr, 2);
    
    // Copy the src element to the current dest index
    LLVMValueRef destPtr = LLVMBuildInBoundsGEP2(state.builder, elementTypeRef, arrayPtr, [counter].ptr, 1, "dest_ptr");
    LLVMBuildStore(state.builder, srcValue, destPtr);

    // if counter == endCounter then goto exit, else loop again
    LLVMValueRef cmp = LLVMBuildICmp(state.builder, LLVMIntPredicate.LLVMIntEQ, counter, endCounterValue, "cmp");
    LLVMBuildCondBr(state.builder, cmp, endBlock, loopBlock);

    // end:
    LLVMPositionBuilderAtEnd(state.builder, endBlock);
}
