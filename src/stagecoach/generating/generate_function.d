module stagecoach.generating.generate_function;

import stagecoach.all;

void generateFunctionDeclaration(Function f, GenerateState state) {

    string name = f.isExtern || f.isMain ? f.name : f.mangledName();

    state.mod.log("Generating function declaration %s(%s)", f.name, f.paramTypes().shortName());

    // Create the type 
    if(f.llvmType is null) {
        f.llvmType = state.getLLVMFunctionType(f);
    }

    // Add the function to the module
    LLVMValueRef funcValue = LLVMAddFunction(state.currentModule, name.toStringz(), f.llvmType);
    f.llvmValueByModule[state.mod.name] = funcValue;

    // Set the linkage and calling convention
    if(f.isExtern || f.isMain) {
        LLVMSetLinkage(funcValue, LLVMLinkage.LLVMExternalLinkage);

        if(f.callingConvention == "WIN64") {
            LLVMSetFunctionCallConv(funcValue, CallingConv.Win64);
        } else {
            LLVMSetFunctionCallConv(funcValue, CallingConv.C);
        }
    } else {

        // If the function is referenced from another Module then it needs to have external linkage
        if(f.isExternallyReferenced) {
            LLVMSetLinkage(funcValue, LLVMLinkage.LLVMExternalLinkage);
        } else {
            LLVMSetLinkage(funcValue, LLVMLinkage.LLVMInternalLinkage);
        }

        LLVMSetFunctionCallConv(funcValue, CallingConv.Fast);
    }

    // Add attributes
    state.addFunctionAttribute(funcValue, "nounwind");
}

void generateFunctionBody(Function f, GenerateState state) {
    if(f.isExtern) return;

    //log("Generating function body %s", f.name);

    LLVMValueRef funcValue = f.llvmValueByModule[state.mod.name];

    state.currentFunction = funcValue;
    
    // Create the entry block
    LLVMBasicBlockRef entry = LLVMAppendBasicBlockInContext(state.context, state.currentFunction, "entry");
    LLVMPositionBuilderAtEnd(state.builder, entry);

    // For each parameter we generate a local alloca so that we can modify the value if required.
    // This will be optimised away later if not used
    foreach(i, v; f.params()) {

        // Remember the lvalue for later
        LLVMValueRef varValue = LLVMBuildAlloca(state.builder, state.getLLVMType(v.getType()), v.name.toStringz());
        v.llvmValueByModule[state.mod.name] = varValue;

        // Store param value into our local lvalue 
        LLVMBuildStore(state.builder, LLVMGetParam(state.currentFunction, i.as!int), varValue);
    }

    // Generate the function body
    foreach(ch; f.bodyStatements()) {
        state.generate(ch);
    }

    // Add implicit return if this is a void function
    if(f.returnType.typeKind() == TypeKind.VOID) {
        bool addRetVoid = f.numChildren() == 0 || !f.last().isA!Return;

        if(addRetVoid) {
            LLVMBuildRetVoid(state.builder);
        }
    }
    //log("  Generated function body %s", f.name);
}
