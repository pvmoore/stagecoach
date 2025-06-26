module stagecoach.generating.generate_if;

import stagecoach.all;

void generateIf(If n, GenerateState state) {
    auto ifBlock = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "if");
    auto thenBlock = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "then");
    auto elseBlock = n.hasElse ? LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "else") : null;
    auto endBlock = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "endif");

    LLVMValueRef[]      phiValues;
    LLVMBasicBlockRef[] phiBlocks;
    Type exprType = n.getType();

    LLVMBuildBr(state.builder, ifBlock);

// if:
    LLVMPositionBuilderAtEnd(state.builder, ifBlock);

    // Condition
    state.generate(n.condition());
    auto conditionI1 = state.castToI1(state.rhs);

    // Branch to then or else
    LLVMBuildCondBr(state.builder, conditionI1, thenBlock, n.hasElse ? elseBlock : endBlock);

// then:
    LLVMPositionBuilderAtEnd(state.builder, thenBlock);
    foreach(ch; n.thenStatements()) {
        state.generate(ch);
    }

    if(n.isExpression()) {
        state.castType(state.rhs, n.thenType(), exprType);

        phiValues ~= state.rhs;
        phiBlocks ~= thenBlock;
    }

    if(!n.thenBlockReturns()) { 
        LLVMBuildBr(state.builder, endBlock);
    }

// else:
    if(n.hasElse) {
        LLVMPositionBuilderAtEnd(state.builder, elseBlock);
        foreach(ch; n.elseStatements()) {
            state.generate(ch);
        }

        if(n.isExpression()) {
            state.castType(state.rhs, n.elseType(), exprType);

            phiValues ~= state.rhs;
            phiBlocks ~= elseBlock;
        }

        if(!n.elseBlockReturns()) { 
            LLVMBuildBr(state.builder, endBlock);
        }
    }

// endif:
    LLVMPositionBuilderAtEnd(state.builder, endBlock);

    if(n.isExpression()) {
        auto phi = LLVMBuildPhi(state.builder, state.getLLVMType(exprType), "if_expr_value");
        LLVMAddIncoming(phi, phiValues.ptr, phiBlocks.ptr, 2);

        state.rhs = phi;
    }
}
