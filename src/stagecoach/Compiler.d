module stagecoach.Compiler;

import stagecoach.all;

final class Compiler {
public:
    enum versionMajor = 0;
    enum versionMinor = 2;
    enum versionPatch = 2;

    this(CompilerOptions options) {
        this.options = options;
        this.llvm = new LLVMTargetMachine(options.targetTriple);
    }
    CompilationError[] compileProject(string filename) {
        consoleLogAnsi(Ansi.CYAN_BOLD ~ Ansi.UNDERLINE, "\nStagecoach Lang v%s.%s.%s", versionMajor, versionMinor, versionPatch);

        this.project = new Project(options, filename);

        auto llvmVersion = getLLVMVersion();
        consoleLog("LLVM version ....... %s.%s.%s", llvmVersion[0], llvmVersion[1], llvmVersion[2]);

        try{
            do{
                consoleLogAnsi(Ansi.CYAN, "─────────────────────────────────────────────────────────── Scanning Modules");
                
                // Start processing the main file. This will pull in imports and process them as well
                project.processMainSourceFile(project.mainFilename);

                // Add common files
                project.processCommonSourceFile("@common.stage");

                consoleLogAnsi(Ansi.CYAN, "─────────────────────────────────────────────────────────── Parsing Modules");
                parseAllModules();
                if(project.hasErrors()) break;

                //debug writeAllModulesAST(project, "_0");

                // If we get here then all of the files have been parsed into AST Modules

                consoleLogAnsi(Ansi.CYAN, "─────────────────────────────────────────────────────────── Resolving Modules");
                bool allResolved = resolveAllModules();
                if(!allResolved) break;

                consoleLogAnsi(Ansi.CYAN, "─────────────────────────────────────────────────────────── Checking Modules");
                if(!checkAllModules(project)) break;

                // Stop here if we are only checking the syntax
                if(options.checkOnly) break;

                consoleLogAnsi(Ansi.CYAN, "─────────────────────────────────────────────────────────── Preparing For Generation");
                flushLogs();

                foreach(m; project.allModules) {
                    m.allModulesChecked();
                }

                consoleLogAnsi(Ansi.CYAN, "─────────────────────────────────────────────────────────── Generating IR");
                if(!generateIRForAllModules()) break;

                flushLogs();

                consoleLogAnsi(Ansi.CYAN, "─────────────────────────────────────────────────────────── Optimising IR");
                if(!llvm.optimiseAllModules(project)) return project.errors;

                debug writeModuleLL(project, project.mainModule);

                consoleLogAnsi(Ansi.CYAN, "─────────────────────────────────────────────────────────── Building Program");
                if(!llvm.buildProject(project)) return project.errors;

                consoleLogAnsi(Ansi.CYAN, "─────────────────────────────────────────────────────────── Linking Program");
                linkProject(project);

                consoleLogAnsi(Ansi.GREEN_BOLD, "Success");
                
            }while(false);
        }catch(Exception e) {
            consoleLogAnsi(Ansi.RED_BOLD, "!! Exception: %s %s:%s %s", e.msg, e.file, e.line, e.info);
        }

        cleanup();

        // todo - sort errors by Module, line; maybe have a compiler option to enable this

        return project.errors;
    }
private:
    CompilerOptions options;
    Project project;
    LLVMTargetMachine llvm;

    void parseAllModules() {
        foreach(mod; project.allModules) {
            auto parseState = new ParseState(project, mod);
            parseStatementsAtModuleScope(parseState);
        }
    }

    bool resolveAllModules() {

        // Create ResolveStates for all Modules
        ResolveState[] resolveStates = project.allModules.map!(m => new ResolveState(project, m)).array;
        bool allResolved = false;
        enum MAX_ITERATIONS = 10;

        // Run the iterations
        foreach(iter; 0..MAX_ITERATIONS) {
            foreach(state; resolveStates) {
                state.startIteration();
                resolve(state);
                state.finishIteration();

                if(state.hasUnresolvedNodes() || state.rewriteOccurred) {
                    log(state.mod, state.getReport());
                }

                debug writeModuleAST(project, state.mod);
            }

            allResolved = resolveStates.all!((s) => !s.hasUnresolvedNodes() && !s.rewriteOccurred);
            if(allResolved) break;
        }

        if(!allResolved) {
            consoleLogAnsi(Ansi.RED_BOLD, "Not all nodes resolved after %s iterations", MAX_ITERATIONS);

            // Exit here if there were any errors
            //if(project.hasErrors()) return false;

            // Convert unresolved nodes to errors
            foreach(state; resolveStates) {
                if(state.hasUnresolvedNodes()) {
                    state.convertUnresolvedNodesToErrors();
                }
            }
            return false;
        }
        return true;
    }
    bool generateIRForAllModules() {
        // Use the same LLVM context for all modules. We do this so that we can link the modules together 
        // before running the optimiser. This requires that the context is the same for all modules.
        // This is less efficient than using a separate context for each module
        // since we can't parallelise the generation and optimisation steps.
        LLVMContextRef context = LLVMContextCreate();
        
        foreach(mod; project.allModules) {    
            auto state = new GenerateState(mod, context);
            if(!generateModule(state)) return false;
        }
        return true;
    }
    /*
    void addCommonCodeModule() {
        Module mod = makeNode!Module(NO_TOKEN);
        mod.project = project;
        mod.name = "@common";
        mod.relFilename = "@common";
        mod.source = null;
        mod.tokens = null;
        project.addModule(mod);

        {
            // Add _ui64toa extern function declaration
            auto ui64toaParams = [
                makeVariable("value", makeSimpleType(TypeKind.LONG), VariableKind.PARAMETER),
                makeVariable("str", makePointerType(makeSimpleType(TypeKind.BYTE)), VariableKind.PARAMETER),
                makeVariable("radix", makeSimpleType(TypeKind.INT), VariableKind.PARAMETER)
            ];
            auto ui64toaFn = makeFunction("_ui64toa", makePointerType(makeSimpleType(TypeKind.BYTE)), ui64toaParams, true, false);
            mod.add(ui64toaFn);
        }
        {
            // Add puts extern function declaration
            auto putsParams = [
                makeVariable("str", makePointerType(makeSimpleType(TypeKind.BYTE)), VariableKind.PARAMETER)
            ];
            auto putsFn = makeFunction("puts", makeSimpleType(TypeKind.INT), putsParams, true, false);
            mod.add(putsFn);
        }
        static if(false) {
            // Add malloc extern function declaration
            auto mallocParams = [
                makeVariable("size", makeSimpleType(TypeKind.LONG), VariableKind.PARAMETER)
            ];
            auto mallocFn = makeFunction("malloc", makePointerType(makeSimpleType(TypeKind.BYTE)), mallocParams, true, false);
            mod.add(mallocFn);
        }
        {
            // Add exit extern function declaration
            auto exitParams = [
                makeVariable("code", makeSimpleType(TypeKind.INT), VariableKind.PARAMETER)
            ];
            auto exitFn = makeFunction("exit", makeSimpleType(TypeKind.VOID), exitParams, true, false);
            mod.add(exitFn);
        }

        // Add @assert function
        auto assertParams = [
            makeVariable("condition", makeSimpleType(TypeKind.BOOL), VariableKind.PARAMETER),
            makeVariable("moduleName", makePointerType(makeSimpleType(TypeKind.BYTE)), VariableKind.PARAMETER),
            makeVariable("line", makeSimpleType(TypeKind.LONG), VariableKind.PARAMETER)
            // Possibly add messageVar as an optional parameter later
        ];

        auto assertFn = makeFunction("@assert", makeSimpleType(TypeKind.VOID), assertParams, false, false);
        mod.add(assertFn);

        Binary b = makeBinary(Operator.EQUAL, makeIdentifier("condition"), makeBoolNumber(false), CONST_BOOL_TYPE);
        
        Statement[] thenStmts;
        {        
            auto v = makeVariable("str2", makeArrayType(makeSimpleType(TypeKind.BYTE), 128), VariableKind.LOCAL);
            thenStmts ~= v;
        }
        {
            auto args = [
                makeIdentifier("line"),
                makeAddressOf(makeIdentifier("str2")),
                makeIntegerNumber(10, CONST_INT_TYPE)
            ];
            thenStmts ~= makeCall("_ui64toa", args);
        }
        {
            thenStmts ~= makeCall("puts", [makeStringLiteral("\u001b[31;1m[ERROR!!]\u001b[0m Assertion failed in Module", true)]);
            thenStmts ~= makeCall("puts", [makeIdentifier("moduleName")]);
        }
        {
            Expression[] args = [
                makeAddressOf(makeIdentifier("str2"))
            ];

            thenStmts ~= makeCall("puts", args);
        }
        {
            thenStmts ~= makeCall("exit", [makeIntegerNumber(-1, CONST_INT_TYPE)]);
        }
        
        // These are available in msvcrt.lib:
        //  - exit 
        //  - putchar 
        //  - puts
        //  - memcmp 
        //  - sprintf_s 
        //  - _itoa 
        //  - _ui64toa

        auto ifStmt = makeIf(b, thenStmts, []);
        assertFn.add(ifStmt);
    }
    */
    void cleanup() { 
        if(llvm) llvm.destroy();
    }
}
