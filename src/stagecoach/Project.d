module stagecoach.Project;

import stagecoach.all;
import std.file : getcwd, exists, mkdirRecurse, read;
import std.path : absolutePath, baseName, buildNormalizedPath, dirName, withExtension;

final class Project {
public:
    // Fixed state
    string mainFilename;
    string directory;   
    string targetDirectory;
    string targetName;

    // Dynamic state
    Module mainModule;
    Module[] allModules;
    Module[string] modulesByFilename;
    Module[string] modulesByName;
    CompilationError[] errors;
    
    // User options
    CompilerOptions options;
    string targetTriple;
    string subsystem;
    bool isDebug;
    string[] libs;

    string[] additionalSourceDirectories = [
        "resources/common_code/"
    ];

    this(CompilerOptions options, string mainFilename) {
        this.options = options;
        this.targetTriple = options.targetTriple;
        this.subsystem = options.subsystem;
        this.isDebug = options.isDebug;
        this.libs = options.libs.dup;

        string workingDirectory = getcwd().replace("\\", "/") ~ "/";
        string normalisedFilename = buildNormalizedPath(mainFilename).replace("\\", "/");

        this.mainFilename = baseName(normalisedFilename);
        this.directory = dirName(normalisedFilename) ~ "/";
        this.targetDirectory = workingDirectory ~ ".target/";
        this.targetName = baseName(normalisedFilename).withExtension("").array;

        this.createTargetDirectory();

        consoleLog("Working directory .. %s", workingDirectory);
        consoleLog("Project directory .. %s", this.directory);
        consoleLog("Main filename ...... %s", this.mainFilename);
        consoleLog("Target directory ... %s", this.targetDirectory);
        consoleLog("Target name ........ %s.exe", this.targetName);
    }

    bool hasErrors() { return errors.length > 0; }

    string getTargetFilename(Module mod, string subdir, string suffix, string extension) {
        subdir = subdir ? subdir ~ "/" : "";
        string dir = targetDirectory ~ subdir;
        return dir ~ mod.name.replace("/", "_") ~ suffix ~ "." ~ extension;
    }

    void addError(CompilationError e) {
        // Don't add the same error more than once
        foreach(er; errors) if(er == e) return;

        errors ~= e;

        // Bail out if this is a SyntaxError
        if(e.kind() == ErrorKind.SYNTAX) { throw new Exception(e.getSummary()); }
    }
    void addModule(Module mod) {
        allModules ~= mod;
        modulesByName[mod.name] = mod;
        modulesByFilename[mod.relFilename] = mod;

        if(!this.mainModule) {
            // This is the main program Module
            this.mainModule = mod;
            mod.isMainModule = true;
        }
    }

    /**
     * - Read the source
     * - Tokenise the source
     * - Scan the source for user defined types, imports and function names
     */
    Module addModuleSourceFile(string relFilename) {

        // Skip if we have already processed this file
        if(relFilename in modulesByFilename) return modulesByFilename[relFilename];

        // Read the source
        string source;

        // Try to read the file from the project directory
        if(exists(this.directory ~ relFilename)) {
            source = read(this.directory ~ relFilename).as!string;
        } else {
            // Look in the additional source directories
            foreach(dir; this.additionalSourceDirectories) {

                if(exists(dir ~ relFilename)) {
                    source = read(dir ~ relFilename).as!string;
                    break;
                }
            }
        }

        // Create and initialise the Module instance
        Module mod = makeNode!Module(0);
        mod.project = this;
        mod.name = toModuleName(relFilename);
        mod.relFilename = relFilename;
        mod.source = source;
        addModule(mod);

        // Lex the source into a Token array
        mod.tokens = new Lexer(mod, source).tokenise();

        // Scan the module for user defined types, imports and function names
        mod.scanResult = scanModule(mod);

        // Slightly hacky. Add an implicit import of module "@common"
        if(mod.name != "@common") {
            processScanImport(mod, ScanImport("@common"), false);
        }

        // Process the imports
        foreach(ScanImport imp; mod.scanResult.imports) {
            processScanImport(mod, imp, true);   
        }

        writeScanResults(this, mod);

        return mod;
    }

    /**
     * Get the external libraries required by the linker.
     * This consists of the C runtime libraries and any user-specified libraries.
     *
     * https://learn.microsoft.com/en-us/cpp/c-runtime-library/crt-library-features?view=msvc-170#c-runtime-lib-files
     *
     */
    string[] getExternalLibs() {
        string[] externalLibs;
        if(isDebug) {
            externalLibs ~= [
                //"ucrtd.lib",                  // MS universal C99 runtime (debug)
                "msvcrtd.lib",                  // MS C initialization and termination (debug)
                "legacy_stdio_definitions.lib", // Required for printf (and probably other stdio functions)
            ];
            //externalLibs ~= [
            //    "libucrtd.lib",
            //    "libcmtd.lib",
            //    "libvcruntimed.lib"
            //];
        } else {
            externalLibs ~= [
                "msvcrt.lib",               // MS C initialization and termination (release)
                //"ucrt.lib",                 // MS universal C99 runtime (release)
                "legacy_stdio_definitions.lib", // Required for printf (and probably other stdio functions)
            ];
            //externalLibs ~= [
            //    "libucrt.lib",
            //    "libcmt.lib",
            //    "libvcruntime.lib"
            //];
        }
        return externalLibs ~ libs;
    }
//──────────────────────────────────────────────────────────────────────────────────────────────────
private:
    void createTargetDirectory() {
        void create(string dir) {
            if(!dir.exists()) {
                mkdirRecurse(dir);
            }
        }
        create(targetDirectory ~ "/scan/");
        create(targetDirectory ~ "/ast/");
        create(targetDirectory ~ "/ll/");
        create(targetDirectory ~ "/logs/");
    } 
    void processScanImport(Module mod, ScanImport imp, bool checkPath) {
        string alias_     = imp.alias_;
        string importName = imp.name;

        // Check for a module importing itself
        if(importName == mod.name) {
            syntaxError(mod, imp.moduleToken.line, imp.moduleToken.column, "Recursive import");
            return;
        }

        // Check if the imported module can be found
        if(checkPath) {
            string path = this.directory ~ toSourceFilename(importName);
            if(!exists(path)) {
                syntaxError(mod, imp.moduleToken.line, imp.moduleToken.column, "Module '%s' (%s) not found".format(importName, path));
                return;
            }
        }

        Module importedModule = addModuleSourceFile(toSourceFilename(importName));

        if(alias_) {
            // Check for duplicate alias
            if(mod.isModuleAlias(alias_)) {
                syntaxError(mod, imp.aliasToken.line, imp.aliasToken.column, "Module alias '%s' already defined".format(alias_));
                return;
            }
            mod.importedModulesQualified[alias_] = importedModule;
            mod.log("  Importing module %s as %s", importName, alias_);
        } else {
            mod.importedModulesUnqualified[importName] = importedModule;
            mod.log("  Importing module %s", importName);
        }   
    }
}
