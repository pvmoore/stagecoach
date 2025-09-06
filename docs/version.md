# Version History

## 0.2.6

- Set maxErrors in CompilerOptions
- Add CompilerOptions.targetType EXE or LIB
- If targetType is EXE add a check for program entry point function eg 'main'
- Move vulkan example code into a lib (libs/vulkan)

## 0.2.5

- Move examples into the test suite
- Improve the test suite

## 0.2.4

- Remove usused resources/common_code directory
- More work on running the test suite

## 0.2.3

- Move common code eg. @common module into its own library (libs/common) 
- Add core and @common libraries as built-in libraries. These are automatically added to every project.
  Later we may allow the user to specify whether or not to include core.

## 0.2.2

- Remove Import class since it is not required
- Move core source code into a lib (libs/core)
- Add libraries. A new import syntax is used for accessing modules from a library

    import core : path

    eg. import core:console

    The available libs need to be added to the CompilerOptions:

    options.addLib(Lib("core", "path/to/libs/core"));

## 0.2.1

- Move @common code out of the project source directory into resources/common_code
- Add initial test suite implementation. Needs more work.

## 0.2.0

- Update to LLVM 21.1.0

## 0.1.0

June 2025 

- Initial release.
