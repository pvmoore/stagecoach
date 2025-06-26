/*
  Example of creating a Module, TargetMachine and PassManager using the CPP API.
*/
#include "llvm/ADT/APInt.h"
#include "llvm/IR/Verifier.h"
#include "llvm/ExecutionEngine/ExecutionEngine.h"
#include "llvm/ExecutionEngine/GenericValue.h"
#include "llvm/ExecutionEngine/MCJIT.h"
#include "llvm/IR/Argument.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/StandardInstrumentations.h"
#include "llvm/MC/TargetRegistry.h"
#include <algorithm>
#include <cstdlib>
#include <memory>
#include <string>
#include <vector>

using namespace llvm;

TargetMachine *createTargetMachine();
void optimise(TargetMachine *Machine, Module *Mod);

Module* createModule(LLVMContext &Context) { 
    Module *mod = new Module("test", Context);

    // putchar decl
    FunctionType* putcharType = FunctionType::get(Type::getInt32Ty(Context), {Type::getInt32Ty(Context)}, false);
    Function *putchar = Function::Create(putcharType, Function::ExternalLinkage, "putchar", mod);
    putchar->setCallingConv(llvm::CallingConv::C);
    
    // FakeAssert function
    FunctionType *fakeAssertType = FunctionType::get(Type::getVoidTy(Context), {Type::getInt32Ty(Context)}, false);
    Function *fakeAssert = Function::Create(fakeAssertType, Function::InternalLinkage, "fakeAssert", mod);
    {
        BasicBlock *BB = BasicBlock::Create(Context, "entry", fakeAssert);
        BasicBlock *ifBB = BasicBlock::Create(Context, "if", fakeAssert);
        BasicBlock *thenBB = BasicBlock::Create(Context, "then", fakeAssert);
        BasicBlock *endifBB = BasicBlock::Create(Context, "endif", fakeAssert);

        BranchInst::Create(ifBB, BB);

        // if
        Argument* ArgX = &*fakeAssert->arg_begin(); // Get the first arg.
        Value* zero = ConstantInt::get(Type::getInt32Ty(Context), 0);

        Value* CondInst = new ICmpInst(ifBB, ICmpInst::ICMP_EQ, ArgX, zero, "==");
        BranchInst::Create(thenBB, endifBB, CondInst, ifBB);

        // then
        CallInst* callPutchar = CallInst::Create(putchar,
                         {ConstantInt::get(Type::getInt32Ty(Context), 39)},
                         Twine::createNull(), thenBB);
        BranchInst::Create(endifBB, thenBB);

        // endif
        ReturnInst::Create(Context, endifBB); 
    }

    // Main function
    {
        FunctionType *mainType = FunctionType::get( Type::getInt32Ty(Context), {}, false);
        Function *main = Function::Create(mainType, Function::ExternalLinkage,"main", mod);
        main->setCallingConv(llvm::CallingConv::C);
        BasicBlock *BB = BasicBlock::Create(Context, "entry", main);

        CallInst* callfa = CallInst::Create(fakeAssert,
                         {ConstantInt::get(Type::getInt32Ty(Context), 1)},
                         Twine::createNull(), BB);
        //callfa->setCallingConv(CallingConv::Fast);

        ReturnInst::Create(Context, ConstantInt::get(Type::getInt32Ty(Context), 0), BB);
    }



    return mod;
}

// static Function *CreateFibFunction(Module *M, LLVMContext &Context) {
//   // Create the fib function and insert it into module M. This function is said
//   // to return an int and take an int parameter.
//   FunctionType *FibFTy = FunctionType::get(Type::getInt32Ty(Context),
//                                            {Type::getInt32Ty(Context)}, false);
//   Function *FibF =
//       Function::Create(FibFTy, Function::ExternalLinkage, "fib", M);

//   // Add a basic block to the function.
//   BasicBlock *BB = BasicBlock::Create(Context, "EntryBlock", FibF);

//   // Get pointers to the constants.
//   Value *One = ConstantInt::get(Type::getInt32Ty(Context), 1);
//   Value *Two = ConstantInt::get(Type::getInt32Ty(Context), 2);

//   // Get pointer to the integer argument of the add1 function...
//   Argument *ArgX = &*FibF->arg_begin(); // Get the arg.
//   ArgX->setName("AnArg");            // Give it a nice symbolic name for fun.

//   // Create the true_block.
//   BasicBlock *RetBB = BasicBlock::Create(Context, "return", FibF);
//   // Create an exit block.
//   BasicBlock* RecurseBB = BasicBlock::Create(Context, "recurse", FibF);

//   // Create the "if (arg <= 2) goto exitbb"
//   Value *CondInst = new ICmpInst(BB, ICmpInst::ICMP_SLE, ArgX, Two, "cond");
//   BranchInst::Create(RetBB, RecurseBB, CondInst, BB);

//   // Create: ret int 1
//   ReturnInst::Create(Context, One, RetBB);

//   // create fib(x-1)
//   Value *Sub = BinaryOperator::CreateSub(ArgX, One, "arg", RecurseBB);
//   CallInst *CallFibX1 = CallInst::Create(FibF, Sub, "fibx1", RecurseBB);
//   CallFibX1->setTailCall();

//   // create fib(x-2)
//   Sub = BinaryOperator::CreateSub(ArgX, Two, "arg", RecurseBB);
//   CallInst *CallFibX2 = CallInst::Create(FibF, Sub, "fibx2", RecurseBB);
//   CallFibX2->setTailCall();

//   // fib(x-1)+fib(x-2)
//   Value *Sum = BinaryOperator::CreateAdd(CallFibX1, CallFibX2,
//                                          "addresult", RecurseBB);

//   // Create the return instruction and add it to the basic block
//   ReturnInst::Create(Context, Sum, RecurseBB);

//   return FibF;
// }

int main(int argc, char **argv) {
  int n = argc > 1 ? atol(argv[1]) : 24;

  InitializeNativeTarget();
  InitializeAllTargetMCs();
  InitializeNativeTargetAsmParser();
  InitializeNativeTargetAsmPrinter();
  LLVMContext Context;

  // Create some module to put our function into it.
  //std::unique_ptr<Module> Owner(new Module("test", Context));
  //Module *M = Owner.get();

  // We are about to create the "fib" function:
  //Function *FibF = CreateFibFunction(M, Context);

  TargetMachine *targetMachine = createTargetMachine();
  assert(targetMachine);

  Module *testMod = createModule(Context);
  errs() << "Constructed module:\n\n---------\n" << *testMod;

  /*
  // Now we going to create JIT
  std::string errStr;
  ExecutionEngine *EE =
    EngineBuilder(std::move(Owner))
    .setErrorStr(&errStr)
    .create();

  if (!EE) {
    errs() << argv[0] << ": Failed to construct ExecutionEngine: " << errStr
           << "\n";
    return 1;
  }
  */

  errs() << "verifying... " << "\n";
  if (verifyModule(*testMod)) {
    errs() << argv[0] << ": Error constructing function!\n";
    return 1;
  }
  errs() << "Ok"
         << "\n";

  /*errs() << "OK\n";
  errs() << "We just constructed this LLVM module:\n\n---------\n" << *M;
  errs() << "---------\nstarting fibonacci(" << n << ") with JIT...\n";*/

  // Optimise
  optimise(targetMachine, testMod);

  errs() << "Optimised module:\n\n---------\n" << *testMod;

  // Call the Fibonacci function with argument n:
  //std::vector<GenericValue> Args(1);
  //Args[0].IntVal = APInt(32, n);
  //GenericValue GV = EE->runFunction(FibF, Args);

  //// import result of execution
  //outs() << "Result: " << GV.IntVal << "\n";

  delete testMod;
  delete targetMachine;
  return 0;
}

void optimise(TargetMachine* Machine, Module* Mod) { 
    PassInstrumentationCallbacks PIC;
    PipelineTuningOptions PTO;
    PassBuilder PB(Machine, PTO, std::nullopt, &PIC);

    bool Debug = false;
    bool VerifyEach = true;

    LoopAnalysisManager LAM;
    FunctionAnalysisManager FAM;
    CGSCCAnalysisManager CGAM;
    ModuleAnalysisManager MAM;

    PB.registerLoopAnalyses(LAM);
    PB.registerFunctionAnalyses(FAM);
    PB.registerCGSCCAnalyses(CGAM);
    PB.registerModuleAnalyses(MAM);
    PB.crossRegisterProxies(LAM, FAM, CGAM, MAM);

    StandardInstrumentations SI(Mod->getContext(), Debug, VerifyEach);
    SI.registerCallbacks(PIC, &MAM);

    ModulePassManager MPM;
    if (VerifyEach) {
      MPM.addPass(VerifierPass());
    }
    auto Passes = "default<O3>";
    if(auto Err = PB.parsePassPipeline(MPM, Passes)) {
      errs() << "parsePassPipeline failed" << "\n ";
    }

    errs() << "Running optimiser"
           << "\n ";
    MPM.run(*Mod, MAM);
    errs() << "Optimisation finished" << "\n";
}

TargetMachine* createTargetMachine() {
  std::string CPUStr, FeaturesStr;
  std::unique_ptr<TargetMachine> TM;

  std::string targetTriple = "x86_64-pc-windows-msvc";

  std::string Error;
  const Target* target = TargetRegistry::lookupTarget(targetTriple.c_str(), Error);
  TargetMachine *machine = nullptr;
  if (target) {
    std::optional<Reloc::Model> RM;
    std::optional<CodeModel::Model> CM;

    TargetOptions TO;
    TO.MCOptions.ABIName = "fast";

    machine =
        target->createTargetMachine(targetTriple.c_str(), "znver3", "+avx2", TO,
                                    RM,
                                CM, CodeGenOptLevel::Aggressive, false);
    if (!machine) {
        printf("Create Target Machine failed: %s\n", Error.c_str());
    } 
  } 
    return machine;
}
