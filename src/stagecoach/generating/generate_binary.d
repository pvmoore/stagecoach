module stagecoach.generating.generate_binary;

import stagecoach.all;

void generateBinary(Binary n, GenerateState state) {
    //consoleLog("Generate Binary left:%s op:%s right:%s", n.left(), n.op, n.right());
    // ------------------------------------------------------ Left hand side
    state.generate(n.left());
    auto leftValue = state.rhs;
    auto assignValue = state.lhs;

    // Handle bool short circuiting
    if(n.op is Operator.BOOL_OR || n.op is Operator.BOOL_AND) {
        handleShortCircuit(n, leftValue, state);
        return;
    }

    // ------------------------------------------------------ Right hand side
    state.generate(n.right());
    auto rightValue = state.rhs;

    bool isReal = n.type.isReal();

    // Convert both sides to a common type
    if(n.op.isBool()) {
        Type ty = selectCommonType(n.leftType(), n.rightType());

        if(ty is null && n.leftType().isPointer() && n.rightType().isPointer()) {
            // Pointers do not have a type in LLVM. Just pick the left hand side Type here
            ty = n.leftType();
        }
        if(ty is null) {
            assert(ty, "Could not find a common type for %s and %s".format(n.leftType(), n.rightType()));
        }

        leftValue = state.castType(leftValue, n.leftType(), ty);
        rightValue = state.castType(rightValue, n.rightType(), ty);
        isReal = ty.isReal();
    } else {
        leftValue = state.castType(leftValue, n.leftType(), n.type);
        rightValue = state.castType(rightValue, n.rightType(), n.type);
    }

    LLVMValueRef genCmp(LLVMRealPredicate realOp, LLVMIntPredicate intOp) {
        if(isReal) {
            return LLVMBuildFCmp(state.builder, realOp, leftValue, rightValue, stringOf(n.op).toStringz());
        }
        return LLVMBuildICmp(state.builder, intOp, leftValue, rightValue, stringOf(n.op).toStringz());
    }
    LLVMValueRef genOp(LLVMOpcode op) {
        return LLVMBuildBinOp(state.builder, op, leftValue, rightValue, stringOf(n.op).toStringz());
    }

    switch(n.op) {
        // Boolean operations
        case Operator.EQUAL: 
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOEQ, LLVMIntPredicate.LLVMIntEQ);
            break;
        case Operator.NOT_EQUAL: 
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealONE, LLVMIntPredicate.LLVMIntNE);
            break;
        case Operator.LT:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOLT, LLVMIntPredicate.LLVMIntSLT);
            break;
        case Operator.ULT:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOLT, LLVMIntPredicate.LLVMIntULT);
            break;
        case Operator.LTE:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOLE, LLVMIntPredicate.LLVMIntSLE);
            break;
        case Operator.ULTE:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOLE, LLVMIntPredicate.LLVMIntULE);
            break;
        case Operator.GT:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOGT, LLVMIntPredicate.LLVMIntSGT);
            break;
        case Operator.UGT:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOGT, LLVMIntPredicate.LLVMIntUGT);
            break;    
        case Operator.GTE:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOGE, LLVMIntPredicate.LLVMIntSGE);
            break;
        case Operator.UGTE:
            state.rhs = genCmp(LLVMRealPredicate.LLVMRealOGE, LLVMIntPredicate.LLVMIntUGE);
            break;    

        // Arithmetic operations
        case Operator.ADD: 
        case Operator.ADD_ASSIGN:
            state.rhs = genOp(n.type.isReal() ? LLVMOpcode.LLVMFAdd : LLVMOpcode.LLVMAdd); 
            break;
        case Operator.SUB: 
        case Operator.SUB_ASSIGN:
            state.rhs = genOp(n.type.isReal() ? LLVMOpcode.LLVMFSub : LLVMOpcode.LLVMSub);
            break;
        case Operator.MUL: 
        case Operator.MUL_ASSIGN:
            state.rhs = genOp(n.type.isReal() ? LLVMOpcode.LLVMFMul : LLVMOpcode.LLVMMul);
            break;
        case Operator.DIV:
        case Operator.DIV_ASSIGN: 
            state.rhs = genOp(n.type.isReal() ? LLVMOpcode.LLVMFDiv : LLVMOpcode.LLVMSDiv);
            break;
        case Operator.UDIV:
        case Operator.UDIV_ASSIGN:
            state.rhs = genOp(LLVMOpcode.LLVMUDiv);
            break;    
        case Operator.MOD:
        case Operator.MOD_ASSIGN:
            state.rhs = genOp(n.type.isReal() ? LLVMOpcode.LLVMFRem : LLVMOpcode.LLVMSRem);
            break;  
        case Operator.UMOD:
        case Operator.UMOD_ASSIGN:
            state.rhs = genOp(LLVMOpcode.LLVMURem);
            break;
        case Operator.BIT_XOR:
        case Operator.BIT_XOR_ASSIGN:
            state.rhs = genOp(LLVMOpcode.LLVMXor);
            break;
        case Operator.BIT_AND:
        case Operator.BIT_AND_ASSIGN:
            state.rhs = genOp(LLVMOpcode.LLVMAnd);
            break;
        case Operator.BIT_OR:
        case Operator.BIT_OR_ASSIGN:
            state.rhs = genOp(LLVMOpcode.LLVMOr);
            break;
        case Operator.SHL:
        case Operator.SHL_ASSIGN:
            state.rhs = genOp(LLVMOpcode.LLVMShl);
            break;
        case Operator.SHR:
        case Operator.SHR_ASSIGN:
            state.rhs = genOp(LLVMOpcode.LLVMAShr);
            break;
        case Operator.USHR:
        case Operator.USHR_ASSIGN:
            state.rhs = genOp(LLVMOpcode.LLVMLShr);
            break;
    
        case Operator.ASSIGN:
            // Do this at the end of the function
            break;
        default:
            throwIf(true, "Handle %s", n.op);
            break;
    }

    if(n.op.isBool()) {
        // Convert the i1 result back into an i8
        state.rhs = LLVMBuildSExt(state.builder, state.rhs, state.INT8_TYPE, "i1-to-i8-");
    }

    // ------------------------------------------------------ Handle assignment
    if(n.op.isAssign()) {
        LLVMBuildStore(state.builder, state.rhs, assignValue);
    }
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

/**
 * Handle the right hand side of a boolean and/or BinaryExpression.
 * In some cases, the result of the left hand side means we don't
 * need to evaluate the right hand side at all.
 */
void handleShortCircuit(Binary n, LLVMValueRef leftValue, GenerateState state) {
    assert(n.type.isBool(), "Expecting the Binary type to be bool (i8)");

    bool isOr          = n.op is Operator.BOOL_OR;
    auto startBlock    = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "%s".format(n.op.stringOf()).toStringz());
    auto rhsLabel	   = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "eval_rhs");
    auto afterRhsLabel = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "after_rhs");

    LLVMBuildBr(state.builder, startBlock);

// start:
    LLVMPositionBuilderAtEnd(state.builder, startBlock);

    // convert leftValue to i1
    auto leftValueI1 = state.castToI1(leftValue);

    if(isOr) {
        // If the left hand side is true, we don't need to evaluate the right hand side
        LLVMBuildCondBr(state.builder, leftValueI1, afterRhsLabel, rhsLabel);
    } else {
        // If the left hand side is false, we don't need to evaluate the right hand side
        LLVMBuildCondBr(state.builder, leftValueI1, rhsLabel, afterRhsLabel);
    }

// eval_rhs:
    LLVMPositionBuilderAtEnd(state.builder, rhsLabel);
    state.generate(n.right());
    state.castType(state.rhs, n.right().getType(), n.type);
    auto rightValue = state.rhs;
    auto rightBlock = LLVMGetInsertBlock(state.builder);
    LLVMBuildBr(state.builder, afterRhsLabel);    

// after_rhs:
    LLVMPositionBuilderAtEnd(state.builder, afterRhsLabel);

    LLVMValueRef[] phiValues      = [leftValue, rightValue];
    LLVMBasicBlockRef[] phiBlocks = [startBlock, rightBlock];

    LLVMValueRef phi = LLVMBuildPhi(state.builder, state.INT8_TYPE, "short_circuit");
    LLVMAddIncoming(phi, phiValues.ptr, phiBlocks.ptr, 2);

    state.rhs = phi;        
}
/*
void handleShortCircuitAlternative(Binary n, LLVMValueRef leftValue, GenerateState state) {
    assert(n.type.isBool(), "Expecting the Binary type to be bool (i8)");

    bool isOr          = n.op is Operator.BOOL_OR;
    auto startBlock    = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "%s".format(n.op.stringOf()).toStringz());
    auto rhsLabel	   = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "eval_rhs");
    auto afterRhsLabel = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "after_rhs");

    LLVMBuildBr(state.builder, startBlock);

    // start:
    LLVMPositionBuilderAtEnd(state.builder, startBlock);

    // Ensure leftValue is i8
    leftValue = state.castType(leftValue, n.leftType(), CONST_BOOL_TYPE);

    /// create a temporary result
    auto resultVal = LLVMBuildAlloca(state.builder, state.createInt8Type(), "bool_result");
    LLVMBuildStore(state.builder, leftValue, resultVal);

    /// do we need to evaluate the right side?
    LLVMIntPredicate cmpOp = isOr ? LLVMIntPredicate.LLVMIntNE : LLVMIntPredicate.LLVMIntEQ;
    LLVMValueRef cmpResult = LLVMBuildICmp(state.builder, cmpOp, leftValue, state.constI8Bool(false), "cmp");
    LLVMBuildCondBr(state.builder, cmpResult, afterRhsLabel, rhsLabel);

// eval_rhs:
    LLVMPositionBuilderAtEnd(state.builder, rhsLabel);
    state.generate(n.right());
    state.castType(state.rhs, n.right().getType(), CONST_BOOL_TYPE);
    LLVMBuildStore(state.builder, state.rhs, resultVal);
    LLVMBuildBr(state.builder, afterRhsLabel);

// after_rhs:
    LLVMPositionBuilderAtEnd(state.builder, afterRhsLabel);   
    state.rhs = LLVMBuildLoad2(state.builder, LLVMInt8TypeInContext(state.context), resultVal, "result");     
}
*/
