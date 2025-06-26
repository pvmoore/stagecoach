module stagecoach.generating.generate_module;

import stagecoach.all;

/**
 * Generate the IR for the given module.
 * 
 * Return true if the module is valid.
 */
bool generateModule(GenerateState state) {
    Module mod = state.mod;

    updateLoggingContext(mod, LoggingStage.Generating);

    state.mod.log("Generating module");

    addModuleInitFunction(state); 

    // Not sure if this is necessary given that the target machine already has this information
    //LLVMSetTarget(state.currentModule, mod.project.targetTriple.toStringz());

    // We need to generate Module scope Variables first because they might be referenced from
    // within a function and we will need the LLVMValueRef of the Variable to be non-null
    
    // Add StringLiterals as global constants
    addStringLiteralGlobals(state);

    //state.log("Generating imported Structs");

    // Generate all imported Module Structs
    foreach(m; mod.allImportedModules()) {
        foreach(n; m.children) {
            if(Struct s = n.as!Struct) {
                generateStruct(s, state);
            }
        }
    }

    //state.log("Generating local Structs");

    // Generate all local Module Structs
    foreach(n; mod.children) {
        if(Struct s = n.as!Struct) {
            generateStruct(s, state);
        }
    }

    //state.log("Generating imported Functions");

    // Generate remote function declarations
    foreach(f; mod.externalFunctions) {
        generateFunctionDeclaration(f, state);
    }

    //state.log("Generating imported Variables");

    // Generate remote variable declarations
    foreach(v; mod.externalVariables) {
        generateVariableDeclaration(v, state);
    }

    //state.log("Generating local Function declarations");

    // Generate all Module function declarations so that the llvmValues are not null
    foreach(n; mod.children) {
        if(Function f = n.as!Function) {
            generateFunctionDeclaration(f, state);
        }
    }

    //state.log("Generating global Variables");

    // Generate all global Variables
    foreach(n; mod.children) {
        if(Variable v = n.as!Variable) {
            state.generate(v);
        }
    }

    //state.log("Generating local Function bodies");

    // Generate Module scope functions 
    foreach(n; mod.children) {
        if(Function f = n.as!Function) {
            generateFunctionBody(f, state);

            //state.log("%s", f.llvmValueByModule[state.mod.name].printValueToString());
        }
    }

    finishModuleInitFunction(state);

    // Dump the LL to file if we are in debug mode
    debug writeLLToFile(mod, mod.project.getTargetFilename(mod, "ll", "", "ll"));

    // Verify the generated IR and return the result. If we are in release mode this will be a no-op
    return state.verifyModule();
}

//──────────────────────────────────────────────────────────────────────────────────────────────────
private:

/**
 * Add a global variable for each string literal. This allows us to reference the string literal
 * from anywhere in the code. LLVM will optimise away any unused string literals.
 *
 * Also, if there are any duplicates we can handle that here.
 */
void addStringLiteralGlobals(GenerateState state) {
    Module mod = state.mod;

    // Collect all unique string literals
    StringLiteral[][string] uniq;
    foreach(l; mod.range().filter!(it=>it.isA!StringLiteral).map!(it=>it.as!StringLiteral)) {
        uniq[l.stringValue] ~= l;
    }

    // Create a global for each unique string literal
    foreach(StringLiteral[] literals; uniq.values) {
        // Create a global from the first literal
        auto lit = literals[0];

        LLVMValueRef stringValue = state.createConstStringValue(lit.stringValue);
        LLVMValueRef global = LLVMAddGlobal(state.currentModule, LLVMTypeOf(stringValue), "str");
        LLVMSetLinkage(global, LLVMLinkage.LLVMInternalLinkage);
        LLVMSetInitializer(global, stringValue);
        LLVMSetGlobalConstant(global, 1);

        // Set all literals with the same llvm value
        foreach(uniqLit; literals) {
            uniqLit.llvmValue = global;
        }
    }
}

void addModuleInitFunction(GenerateState state) {

    state.switchToInitFunctionBuilder();

    string name = "@init-" ~ state.mod.name;

    LLVMTypeRef functionType = LLVMFunctionType(state.VOID_TYPE, null, 0, 0);
    state.initFunctionValue = LLVMAddFunction(state.currentModule, name.toStringz(), functionType);
    LLVMSetLinkage(state.initFunctionValue, LLVMLinkage.LLVMInternalLinkage);
    LLVMSetFunctionCallConv(state.initFunctionValue, CallingConv.Fast);

    // Create the entry block
    LLVMBasicBlockRef entryBlock = LLVMAppendBasicBlockInContext(state.context, state.initFunctionValue, "entry");
    LLVMPositionBuilderAtEnd(state.builder, entryBlock);

    state.switchToNormalBuilder();

    // Add @llvm.global_ctors to the module
    LLVMTypeRef structType = LLVMStructTypeInContext(state.context, 
        [state.INT32_TYPE, state.VOID_PTR_TYPE, state.VOID_PTR_TYPE].ptr, 3, 0);
    LLVMTypeRef globalType = LLVMArrayType2(structType, 1);

    LLVMValueRef globalCtors = LLVMAddGlobal(state.currentModule, globalType, "llvm.global_ctors"); 
    LLVMSetLinkage(globalCtors, LLVMLinkage.LLVMAppendingLinkage);

    LLVMValueRef[] structElements = [
        state.createConstI32Value(65535), 
        state.initFunctionValue,
        LLVMConstPointerNull(state.VOID_PTR_TYPE)
    ];
    
    LLVMValueRef structValue = state.createConstStructValue(structElements);

    LLVMSetInitializer(globalCtors, LLVMConstArray2(structType, &structValue, 1));
}
void finishModuleInitFunction(GenerateState state) {
    state.switchToInitFunctionBuilder();
    LLVMBuildRetVoid(state.builder);
}
