module stagecoach.generating.generate_call;

import stagecoach.all;

void generateCall(Call n, GenerateState state) {
    LLVMValueRef funcValue = n.target.getLLVMValue();
    assert(funcValue);

    Function func = n.target.isFunction() ? n.target.func : n.target.var.getType().extract!Function;
    assert(func);

    Type returnType = n.target.returnType();
    Type[] paramTypes = n.target.paramTypes();
    bool hasVarargParam = n.target.hasVarargParam();

    Expression[] arguments = n.arguments(); 

    // If the function does not have varargs then the number of args should be the same as the number of params
    if(!hasVarargParam) {   
        assert(arguments.length == paramTypes.length);
    }

    int numParams = n.target.numParams() - (hasVarargParam ? 1 : 0);

    // Generate the argument values
    LLVMValueRef[] args = new LLVMValueRef[arguments.length];
    foreach(i, arg; arguments) {
        state.generate(arg);
        if(i < numParams) {
            state.castType(state.rhs, arg.getType(), paramTypes[i]);
        } else {
            // This must be a vararg call
            assert(hasVarargParam);
        }
        args[i] = state.rhs;
    }

    //consoleLog("args = %s", args.map!(v=>v.printValueToString()).array);

    // Get the FunctionType
    LLVMTypeRef returnTypeRef = state.getLLVMType(returnType);
    LLVMTypeRef[] paramTypesRef = paramTypes.filter!(it=>it.typeKind() != TypeKind.C_VARARGS)
                                            .map!(it => state.getLLVMType(it))
                                            .array;
    LLVMTypeRef functionType = LLVMFunctionType(returnTypeRef, paramTypesRef.ptr, paramTypesRef.length.as!uint, hasVarargParam);

    if(n.target.isVariable()) {
        // We need to load the function value from the variable storage
        assert(n.target.var.getType().exactlyMatches(func));
        funcValue = LLVMBuildLoad2(state.builder, state.getLLVMType(n.target.var.getType()), funcValue, n.name.toStringz());
    }

    // Call the function
    auto name = (returnType.isVoidValue() ? null : n.name).toStringz();
    state.rhs = LLVMBuildCall2(state.builder, functionType, funcValue, args.ptr, args.length.as!uint, name);

    // Set the calling convention
    if(n.target.isExtern()) {
        if(func.callingConvention == "WIN64") {
            LLVMSetInstructionCallConv(state.rhs, CallingConv.Win64);
        } else {
            LLVMSetInstructionCallConv(state.rhs, CallingConv.C);
        }
    } else {
        LLVMSetInstructionCallConv(state.rhs, CallingConv.Fast);
    }
}
