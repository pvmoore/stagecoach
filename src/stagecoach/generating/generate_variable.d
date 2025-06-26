module stagecoach.generating.generate_variable;

import stagecoach.all;

void generateVariable(Variable n, GenerateState state) {
    if(n.vkind == VariableKind.LOCAL) {
        generateLocal(n, state);
    } else {
        generateGlobal(n, state);
    }
    state.lhs = n.llvmValueByModule[state.mod.name];
}

void generateVariableDeclaration(Variable n, GenerateState state) {
    // This should only apply to external globals
    if(n.vkind == VariableKind.GLOBAL) {
        LLVMValueRef varValue = LLVMAddGlobal(state.currentModule, state.getLLVMType(n.getType()), n.name.toStringz());
        n.llvmValueByModule[state.mod.name] = varValue;
        
        LLVMSetLinkage(varValue, LLVMLinkage.LLVMExternalLinkage);
        // LLVMSetLinkage(varValue, LLVMLinkage.LLVMExternalWeakLinkage);
        //LLVMSetLinkage(varValue, LLVMLinkage.LLVMCommonLinkage);

        //LLVMSetInitializer(varValue, LLVMConstNull(state.getLLVMType(n.getType())));
    }
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

void generateLocal(Variable n, GenerateState state) {

    LLVMTypeRef llvmType = state.getLLVMType(n.getType());
    LLVMValueRef varPtr = LLVMBuildAlloca(state.builder, llvmType, n.name.toStringz());
    
    n.llvmValueByModule[state.mod.name] = varPtr;
    state.lhs = varPtr;

    if(n.hasInitialiser()) {
        state.generate(n.initialiser());
        state.castType(state.rhs, n.initialiser().getType(), n.getType());
        LLVMBuildStore(state.builder, state.rhs, varPtr);
    } else {
        LLVMBuildStore(state.builder, LLVMConstNull(llvmType), varPtr);
        setDefaultInitialiser(n, varPtr, llvmType, state);
    }
}

void generateGlobal(Variable n, GenerateState state) {

    LLVMTypeRef llvmType = state.getLLVMType(n.getType());
    LLVMValueRef varPtr = LLVMAddGlobal(state.currentModule, llvmType, n.name.toStringz());

    n.llvmValueByModule[state.mod.name] = varPtr;
    state.lhs = varPtr;

    if(n.isExternallyReferenced) {
        LLVMSetLinkage(varPtr, LLVMLinkage.LLVMExternalLinkage);
    } else {
        LLVMSetLinkage(varPtr, LLVMLinkage.LLVMInternalLinkage);
    }

    if(n.hasInitialiser()) {
        state.generate(n.initialiser());
        state.castType(state.rhs, n.initialiser().getType(), n.getType());
        LLVMSetInitializer(varPtr, state.rhs);
    } else {
        LLVMSetInitializer(varPtr, LLVMConstNull(llvmType));

        state.switchToInitFunctionBuilder();
        setDefaultInitialiser(n, varPtr, llvmType, state);
        state.switchToNormalBuilder();
    }
} 

void setDefaultInitialiser(Variable n, LLVMValueRef varPtr, LLVMTypeRef llvmType, GenerateState state) {
    if(n.getType().isPointer()) {
        
    } else if(n.getType().isEnum()) {
        // Enums are initialised to the first enum value
        Enum en = n.getType().extract!Enum;
        EnumMember member = en.getMemberByIndex(0);
        state.generate(member);
        state.castType(state.rhs, member.getType(), n.getType());
        LLVMBuildStore(state.builder, state.rhs, varPtr);
    } else if(ArrayType array = n.getType().extract!ArrayType) {
        defaultInitialiseArray(array, varPtr, state);
    } else if(Struct st = n.getType().extract!Struct) {
        defaultInitialiseStruct(st, varPtr, state);
    } 
}
