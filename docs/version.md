# Version History

## 0.2.2

September 2025

- Remove Import class since it is not required
- Move core source code into a lib (libs/core)
- Add libraries. A new import syntax is used for accessing modules from a library

    import core : path

    eg. import core:console

    The available libs need to be added to the CompilerOptions:

    options.addLib(Lib("core", "path/to/libs/core"));

## 0.2.1

September 2025

- Move @common code out of the project source directory into resources/common_code
- Add initial test suite implementation. Needs more work.

## 0.2.0

September 2025

- Update to LLVM 21.1.0

## 0.1.0

June 2025 

- Initial release.
