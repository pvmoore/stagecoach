module stagecoach.llvm.llvm_target_machine;

import stagecoach.all;

final class LLVMTargetMachine {
public:
    this(string targetTriple) {
        this.targetTriple = targetTriple;

        LLVMEnablePrettyStackTrace();

        LLVMInitializeX86TargetInfo();
        LLVMInitializeX86Target();
        LLVMInitializeX86TargetMC();
        LLVMInitializeX86AsmPrinter();
        LLVMInitializeX86AsmParser();
        LLVMInitializeX86Disassembler();

        this.targetMachine = createTargetMachine();
    }
    void destroy() {
        LLVMDisposeTargetMachine(targetMachine);
    }

    bool optimiseSingleModule(Module mod) {
        LLVMPassBuilderOptionsRef options = createPassOptions();
        checkError(LLVMRunPasses(mod.llvmModule, "default<O3>", targetMachine, options));
        return true;
    }
    /**
     * Link all the modules together and then optimise the main module.
     *  
     * It might be better to optimise the modules individually, create an object for each module,
     * then link all of the objects later. This would mean we could probably run the generate and
     * optimise steps in parallel.
     *
     * If you link all the modules together like we do here then the LLVM context must be the same
     * for all modules.
     */
    bool optimiseAllModules(Project project) {
        Module mainModule = project.mainModule;
        Module[] allModules = project.allModules;

        if(!linkModules(mainModule, allModules)) {
            log(mainModule, "Failed to link modules together");
            return false;
        }

        static if(true) {
            log(mainModule, "Optimising main module");
            // Run the optimisation passes on mainModule
            LLVMPassBuilderOptionsRef options = createPassOptions();
            if(LLVMErrorRef err = LLVMRunPasses(mainModule.llvmModule, "default<O3>", targetMachine, options)) {
                log(mainModule, "Optimisation failed: %s", LLVMGetErrorMessage(err).fromStringz());
                return false;
            }
        }
        return true;
    }
    bool buildProject(Project project) {
        Module mainModule = project.mainModule;
        log(mainModule, "Building project");
        
        LLVMSetTargetMachineAsmVerbosity(targetMachine, 1);

        // Enabling this causes a translate phase failure (maybe LLVM bug?)
        //LLVMSetTargetMachineGlobalISel(targetMachine, 1);

        string bcFile = project.targetDirectory ~ project.targetName ~ ".bc";
        string asmFile = project.targetDirectory ~ project.targetName ~ ".asm";
        string objFile = project.targetDirectory ~ project.targetName ~ ".obj";

        char* error;
        scope(exit) if(error !is null) LLVMDisposeMessage(error);
    
        //log("  Writing bc file");
        if(LLVMWriteBitcodeToFile(mainModule.llvmModule, bcFile.toStringz())) {
            log(mainModule, "Failed to write bc file");
            return false;
        }
        //log("  Creating asm");
        if(LLVMTargetMachineEmitToFile(targetMachine, mainModule.llvmModule, asmFile.toStringz(),
            LLVMCodeGenFileType.LLVMAssemblyFile, &error)) {
            log(mainModule, "Failed to write asm file: %s", error.fromStringz());
            return false;
        }
        //log("  Creating obj");
        if(LLVMTargetMachineEmitToFile(targetMachine, mainModule.llvmModule, objFile.toStringz(),
            LLVMCodeGenFileType.LLVMObjectFile, &error)) {
            log(mainModule, "Failed to write object file: %s", error.fromStringz());
            return false;
        }
        return true;
    }
private:
    string targetTriple;

    LLVMTargetMachineRef targetMachine;

    LLVMTargetMachineRef createTargetMachine() {
        auto targetTriplez = targetTriple.toStringz();
        char* error;
        LLVMTargetRef targetRef;
        LLVMBool r = LLVMGetTargetFromTriple(targetTriplez, &targetRef, &error);
        if(r!=0 || targetRef is null) {
            consoleLog("Target triple error: %s", error.fromStringz());
        }

        // Get the list of available CPUs and features by running:
        // llc -march=x86 -mattr=help

        LLVMTargetMachineOptionsRef options = LLVMCreateTargetMachineOptions();
        LLVMTargetMachineOptionsSetCPU(options, "znver3");
        LLVMTargetMachineOptionsSetFeatures(options, "+avx2");
        LLVMTargetMachineOptionsSetABI(options, "fast");
        LLVMTargetMachineOptionsSetCodeGenOptLevel(options, LLVMCodeGenOptLevel.LLVMCodeGenLevelAggressive);
        LLVMTargetMachineOptionsSetRelocMode(options, LLVMRelocMode.LLVMRelocDefault);
        LLVMTargetMachineOptionsSetCodeModel(options, LLVMCodeModel.LLVMCodeModelDefault);

        LLVMTargetMachineRef theTargetMachine = LLVMCreateTargetMachineWithOptions(targetRef, targetTriplez, options);
        // log(" LLVMTargetMachineRef = %s", theTargetMachine);
        // log(" Features: %s", LLVMGetTargetMachineFeatureString(theTargetMachine).fromStringz());

        //LLVMTargetDataRef dataLayout = LLVMCreateTargetDataLayout(theTargetMachine);
        //log(" LLVMTargetDataRef = %s", dataLayout);
        return theTargetMachine; 
    }
    LLVMPassBuilderOptionsRef createPassOptions() {
        // New pass manager
        LLVMPassBuilderOptionsRef passBuilderOptions = LLVMCreatePassBuilderOptions();
        // Toggle debug logging when running the PassBuilder. 
        LLVMPassBuilderOptionsSetDebugLogging(passBuilderOptions, 0);

        // Enable/disable loop interleaving
        LLVMPassBuilderOptionsSetLoopInterleaving(passBuilderOptions, 0);

        // Enable/disable loop vectorization
        LLVMPassBuilderOptionsSetLoopVectorization(passBuilderOptions, 0);

        // Enable/disable slp loop vectorization
        LLVMPassBuilderOptionsSetSLPVectorization(passBuilderOptions, 0);

        // Enable/disable loop unrollin
        LLVMPassBuilderOptionsSetLoopUnrolling(passBuilderOptions, 0);

        // I think this is a code size optimisation :: https://llvm.org/docs/MergeFunctions.html
        LLVMPassBuilderOptionsSetMergeFunctions(passBuilderOptions, 0);

        // Toggle adding the VerifierPass for the PassBuilder, ensuring all functions inside the module is valid. 
        LLVMPassBuilderOptionsSetVerifyEach(passBuilderOptions, 0);
        
        // Other options that could be useful but I don't know enough about them
        //LLVMPassBuilderOptionsSetAAPipeline(passBuilderOptions, "?");
        //LLVMPassBuilderOptionsSetForgetAllSCEVInLoopUnrolling(passBuilderOptions, 1);
        //LLVMPassBuilderOptionsSetLicmMssaOptCap(passBuilderOptions, ?);
        //LLVMPassBuilderOptionsSetLicmMssaNoAccForPromotionCap(passBuilderOptions, ?);
        //LLVMPassBuilderOptionsSetCallGraphProfile(passBuilderOptions, 1);
        //LLVMPassBuilderOptionsSetInlinerThreshold(passBuilderOptions, 25);

        return passBuilderOptions;
    }
    void checkError(LLVMErrorRef err) {
        throwIf(err !is null, "%s".format(LLVMGetErrorMessage(err).fromStringz()));
    }
    /**
     * Link modules together
     *
     * After this step, mainModule.llvmModule contains all the LLVM code 
     */
    bool linkModules(Module mainModule, Module[] allModules) {
        // Exit if we only have one module
        if(allModules.length == 1) return true;

        LLVMModuleRef dest = mainModule.llvmModule;
        LLVMModuleRef[] srcModules = allModules.filter!(it=>it !is mainModule)
                                                .map!(m => m.llvmModule)
                                                .array;

        log(mainModule, "Linking modules into [%s] <- %s", mainModule.name, allModules.filter!(it=>it !is mainModule).map!(m => m.name).array);                                                

        foreach(LLVMModuleRef o; srcModules) {
            LLVMBool res = LLVMLinkModules2(dest, o);
            if(res!=0) return false;
        }
        return true;
    }
}
