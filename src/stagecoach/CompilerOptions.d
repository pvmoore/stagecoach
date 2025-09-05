module stagecoach.CompilerOptions;

import stagecoach.all;

final class CompilerOptions {
public:
    static struct Lib {
        string name;                // eg. "core"
        string sourceDirectory;     // eg. "C:/work/stagecoach/libs/core"
        string libFile;             // eg. "C:/work/stagecoach/libs/core/lib/libcore.lib" 
    }

    string targetTriple = "x86_64-pc-windows-msvc";
    string subsystem = "console";

    bool isDebug = true;
    bool checkOnly = false;

    bool enableAsserts = true;
    bool enableNullChecks = true; 
    bool enableBoundsChecks = true;

    bool writeObj = false;
    bool writeLL = false;
    bool writeAST = false;

    this() {
        CompilerOptions.Lib coreLib = {
            name: "core",
            sourceDirectory: "libs/core",
            libFile: null
        };

        CompilerOptions.Lib commonLib = {
            name: "@common",
            sourceDirectory: "libs/common",
            libFile: null
        };

        addLib(coreLib);
        addLib(commonLib);
    }

    Lib[] getLibs() { return libs; }

    Lib* getLib(string name) {
        foreach(i, lib; libs) if(lib.name == name) return &libs[i];
        return null;
    }

    void addLib(Lib lib) {
        if(auto prevLib = getLib(lib.name)) {
            throw new Exception("Library '%s' already defined".format(lib.name));
            return;
        }

        if(lib.sourceDirectory) {
            lib.sourceDirectory = toCanonicalPath(lib.sourceDirectory, false);
        }

        libs ~= lib;
    }

    override string toString() {
        return ("CompilerOptions {\n" ~
            "  targetTriple: %s\n" ~
            "  subsystem: %s\n" ~
            "  isDebug: %s\n" ~
            "  checkOnly: %s\n" ~
            "  enableAsserts: %s\n" ~
            "  enableNullChecks: %s\n" ~
            "  enableBoundsChecks: %s\n" ~
            "  writeObj: %s\n" ~
            "  writeLL: %s\n" ~
            "  writeAST: %s\n" ~
            "  libs: %s\n" ~
            "}").format(
                targetTriple, 
                subsystem, 
                isDebug, 
                checkOnly, 
                enableAsserts, 
                enableNullChecks, 
                enableBoundsChecks, 
                writeObj, 
                writeLL, 
                writeAST,
                libs); 
    }
//──────────────────────────────────────────────────────────────────────────────────────────────────
private:
    Lib[] libs;
}
