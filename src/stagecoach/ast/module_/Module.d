module stagecoach.ast.module_.Module;

import stagecoach.all;
import std.algorithm : canFind;

final class Module : Node {
public:
    // static state
    Project project;
    string name;
    string relFilename;
    string source;
    Token[] tokens;
    bool isMainModule;          // true if this is the first/main module of the program

    // dynamic state
    ScanResult scanResult;                      // Result of scanning the module (contains UDTs, imports and function names)
    Module[string] importedModulesQualified;    // Map of import alias to Module
    Module[string] importedModulesUnqualified;  // Unqualified Modules imported by this Module
                                                // (May contain duplicate Modules if the same module is imported with different aliases)
    LLVMModuleRef llvmModule;                   // The LLVM handle set by LLVMIRGenerator
    Function[] externalFunctions;               // List of external Module Functions referenced by this Module
    Variable[] externalVariables;               // List of external Module Variables referenced by this Module

    // Node
    override NodeKind nodeKind() { return NodeKind.MODULE; }
    override bool isResolved() { return true; }

    Module[] allImportedModules() {
        return unique(importedModulesUnqualified.values ~ importedModulesQualified.values);
    }

    bool hasFunction(string name) {
        return this.childrenOfType!Function().canFind!((f) => f.name == name);
    }

    bool isModuleAlias(string name) {
        return importedModulesQualified.containsKey(name);
    }

    bool isUDT(string name, Module requestingModule, string moduleAlias) {
        bool requestingModuleIsThis = requestingModule is this;
        if(UDT* u = name in scanResult.udts) {
            return requestingModuleIsThis || u.isPublic;
        }
        if(requestingModuleIsThis) {
            if(moduleAlias) {
                // Check qualified imports for public Types with the right name
                if(auto m = importedModulesQualified.get(moduleAlias, null)) {
                    return m.isUDT(name, requestingModule, null);
                }
            } else {
                // Check unqualified imports for public Types with the right name
                foreach(m; importedModulesUnqualified.values) {
                    if(m.isUDT(name, requestingModule, null)) return true;
                }
            }
        }
        return false;
    }

    Token getToken(int index) {
        return index < tokens.length ? tokens[index] : NO_TOKEN;
    }

    // bool isUDT(string name, bool localOnly = false) {
    //     if(UDT* u = name in scanResult.udts) {
    //         if(!localOnly || u.isPublic) return true;
    //     }

    //     if(!localOnly) {
    //         // Check unqualified imports for public Types with the right name
    //         foreach(m; importedModulesUnqualified.values) {
    //             if(m.isUDT(name, true)) return true;
    //         }
    //     }
    //     return false;
    // }

    // bool isUDT(string name, string moduleAlias) {
    //     if(auto m = importedModulesQualified.get(moduleAlias, null)) {
    //         return m.isUDT(name, true);
    //     }
    //     return false;
    // }

    /**
     * Find a user defined type by name. This will include all locally defined UDTs and also
     * any UDTs imported from other modules. Returns null if the UDT is not found.
     *
     *  - Struct
     *  - Alias
     *  - Union     *todo
     *  - Enum      
     */
    Type getUDT(string name, bool includeImports = true) {
        foreach(t; this.childrenOfType!Type()) {
            if(Struct st = t.as!Struct) {
                if(st.name == name) return t;
            } else if(Alias a = t.as!Alias) {
                if(a.name == name) return t;
            } else if(Enum e = t.as!Enum) {
                if(e.name == name) return t;
            }

            // todo - add Union here when implemented
        }
        if(includeImports) { 
            foreach(m; importedModulesUnqualified.values) {
                if(auto t = m.getUDT(name, false)) {
                    if(isPublic(t)) {
                        return t;
                    }
                }
            }
        }
        return null;
    }

    /**
     * Called after all modules have been resolved and checked.
     *
     * Use this opportunity to calculate which Functions are referenced.
     */
    void allModulesChecked() {
        getRemoteModuleReferences();

        // foreach(f; this.childrenOfType!Function()) {
        //     f.isExternallyReferenced = true;
        // }
        log(this, "External Functions: %s", externalFunctions.map!(f => f.name).array);
        log(this, "External Variables: %s", externalVariables.map!(v => v.name).array);
    }

    override int opCmp(Object other) {
        import std.algorithm : cmp;
        assert(other.isA!Module);
        return this.name.cmp(other.as!Module.name);
    }
    override string toString() {
        return "Module(" ~ name ~ ")";
    }
private:
    void getRemoteModuleReferences() {
        bool[Function] funcs;
        bool[Variable] vars;

        foreach(n; this.range()) {
            if(Call c = n.as!Call) {
                if(c.target.isRemote()) {
                    if(c.target.isVariable()) {
                        vars[c.target.var] = true;
                        c.target.var.isExternallyReferenced = true;
                    } else {
                        funcs[c.target.func] = true;
                        c.target.func.isExternallyReferenced = true;
                    }
                }
            }
        }
        this.externalFunctions = funcs.keys();
        this.externalVariables = vars.keys();
    }
}
