module stagecoach.linking.ms_linker;

import stagecoach.all;

import std.process : spawnProcess, wait;

/**
 * Call the MS Linker.
 *
 * This file is Windows specific.
 */
bool msLink(Project project) {
    string objFile = project.targetDirectory ~ project.targetName ~ ".obj";
    string exeFile = project.targetDirectory ~ project.targetName ~ ".exe";

    auto args = [
        "link",
        "/NOLOGO",
        //"/VERBOSE",
        "/MACHINE:X64",
        "/WX",              /// Treat linker warnings as errors
        "/SUBSYSTEM:" ~ project.subsystem
    ];

    if(project.isDebug) {
        args ~= [
            "/DEBUG:NONE",  /// Don't generate a PDB for now
            "/OPT:NOREF"    /// Don't remove unreferenced functions and data
        ];
    } else {
        args ~= [
            "/RELEASE",
            "/OPT:REF",     /// Remove unreferenced functions and data
            //"/LTCG",        /// Link time code gen
        ];
    }

    args ~= [
        objFile,
        "/OUT:" ~ exeFile
    ];

    args ~= project.getExternalLibs();

    // log("linker args: \n%s", args.join("\n  "));

    int returnStatus;
    string errorMsg;
    try{
        auto pid = spawnProcess(args);
        returnStatus = wait(pid);
    }catch(Exception e) {
        errorMsg     = e.msg;
        returnStatus = -1;
    }

    if(returnStatus != 0) {
        consoleLog("Linker failed: %s", errorMsg);
    }

    /// Delete the obj file if required
    // if(project.deleteObjFile) {
    //     import std.file : remove;
    //     remove(objFile);
    // }

    return returnStatus==0;
}
