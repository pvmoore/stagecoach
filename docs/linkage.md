
# LLVM Linkage Types

* ExternalLinkage (LLVMExternalLinkage)
  - Global values with external linkage are visible to code outside the current module.
  - Can be referenced from other modules and linked against.
  - This is the default for global declarations and definitions.

* AvailableExternallyLinkage (LLVMAvailableExternallyLinkage)
  - Similar to external linkage, but indicates the symbol can be optimized/removed.
  - The definition is known to exist elsewhere, so the current definition can be omitted.
  - Cannot have initializer (for globals), must be declarations.

* LinkOnceAnyLinkage (LLVMLinkOnceAnyLinkage)
  - At most one copy of the symbol will be included in the final program.
  - Can be merged with other symbols of the same name during linking.
  - Used for inline functions, templates, or other code that may be defined in multiple modules.

* LinkOnceODRLinkage (LLVMLinkOnceODRLinkage)
  - Same as LinkOnceAny, but enforces One Definition Rule (ODR).
  - All copies of the symbol must be equivalent after linking.
  - Commonly used for C++ inline functions and templates.

* WeakAnyLinkage (LLVMWeakAnyLinkage)
  - Similar to LinkOnceAny, but won't be removed if unreferenced.
  - Multiple copies allowed but linker will only include one.
  - If both weak and strong definitions exist, strong definition is chosen.

* WeakODRLinkage (LLVMWeakODRLinkage)
  - Same as WeakAny but enforces One Definition Rule.
  - All definitions must be equivalent.
  - Used for C++ template instantiations.

* AppendingLinkage (LLVMAppendingLinkage)
  - Used for global arrays that are linked together.
  - Arrays with this linkage are concatenated together during linking.
  - Commonly used for global constructors/destructors arrays.

* InternalLinkage (LLVMInternalLinkage)
  - Symbol is not visible outside current module.
  - Similar to 'static' functions/variables in C.
  - Can be optimized/renamed freely by the compiler.

* PrivateLinkage (LLVMPrivateLinkage)
  - More restrictive than Internal linkage.
  - Not visible in symbol table.
  - Can only be referenced directly, cannot be address-taken.

* ExternalWeakLinkage (LLVMExternalWeakLinkage)
  - Like external linkage but weak.
  - If symbol is not defined after linking, it resolves to null instead of error.
  - Similar to "extern __attribute__((weak))" in C.

* CommonLinkage (LLVMCommonLinkage)
  - Merged with other symbols of same name during linking.
  - Zero-initialized.
  - Similar to uninitialized global variables in C (tentative definitions).
