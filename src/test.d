module test;

import std.stdio;

import stagecoach;

void main() {
    
    auto options = new CompilerOptions();
    options.writeLL = true;
    options.writeAST = true;
    options.writeObj = true;
    options.checkOnly = false;
    options.subsystem = "console";
    
    options.isDebug = true;

    options.enableAsserts = true;
    options.enableNullChecks = true;
    options.enableBoundsChecks = true;

    Compiler compiler = new Compiler(options);
    auto errors = compiler.compile("examples/test.stage");

    // Log the errors if there were any
    if(errors.length > 0) {

        // todo - sort the errors by module and line number

        writefln("");

        foreach(i, e; errors) {
            writefln("(\u001b[33;1m%s\u001b[0m) \u001b[36m%s\u001b[0m", i+1, e.getLocationString());
            if(i == 0) {
                writefln("%s", e.getPrettyString());

                string extraInfo = e.getExtraInfo();

                if(extraInfo.length > 0) {
                    writefln("%s", extraInfo);
                }

                if(errors.length > 1) writefln("────────────────────────────────────────────────────────────────");
            } else {
                writefln("    %s", e.getSummary());
            }
        }
    }


    /*
    static struct Fig {
        int a;
        float b;
        bool c;
        short d;
        byte e;
        long f;
    }
    static struct Fig2 {
        byte a;
    }

    // writefln("alignOf Fig = %s", Fig.alignof);
    // writefln("alignOf Fig2 = %s", Fig2.alignof);
    // writefln("alignOf Fig.a = %s", Fig.a.alignof);
    // writefln("alignOf Fig.b = %s", Fig.b.alignof);
    // writefln("alignOf Fig.c = %s", Fig.c.alignof);
    // writefln("alignOf Fig.d = %s", Fig.d.alignof);
    // writefln("alignOf Fig.e = %s", Fig.e.alignof);
    // writefln("alignOf Fig.f = %s", Fig.f.alignof);

    writefln("offsetof Fig.a = %s", Fig.a.offsetof);
    writefln("offsetof Fig.b = %s", Fig.b.offsetof);
    writefln("offsetof Fig.c = %s", Fig.c.offsetof);
    writefln("offsetof Fig.d = %s", Fig.d.offsetof);
    writefln("offsetof Fig.e = %s", Fig.e.offsetof);
    writefln("offsetof Fig.f = %s", Fig.f.offsetof);

    static struct Gnat {
        byte a;
    }
    static struct Chicken { // size = 8
        int a;      // 0 
        bool b;     // 4
        short c;    // 6
    }
    static struct Egg {    // size = 16
        bool a;     // 0
        Chicken b;  // 4
        int c;      // 12
    }
    static struct BigGnat { // size = 2
        byte a;
        Gnat b;
    }

    writefln("Gnat.sizeof = %s", Gnat.sizeof);
    writefln("BigGnat.sizeof = %s", BigGnat.sizeof);

    writefln("Chicken.sizeof = %s", Chicken.sizeof);
    writefln("Egg.sizeof = %s", Egg.sizeof);

    writefln("offsetof Egg.a = %s", Egg.a.offsetof);
    writefln("offsetof Egg.b = %s", Egg.b.offsetof);
    writefln("offsetof Egg.c = %s", Egg.c.offsetof);

    writefln("offsetof Chicken.a = %s", Chicken.a.offsetof);
    writefln("offsetof Chicken.b = %s", Chicken.b.offsetof);
    writefln("offsetof Chicken.c = %s", Chicken.c.offsetof);

    writefln("offsetof Egg.b.a = %s", Egg.b.a.offsetof);
    writefln("offsetof Egg.b.b = %s", Egg.b.b.offsetof);
    writefln("offsetof Egg.b.c = %s", Egg.b.c.offsetof);
*/

    // struct A {
    //     int a;
    //     float f;
    //     bool b;
    // }
    // writefln("size = %s", A.sizeof);

    // static struct AA {
    //     int a;
    // }

    // enum TE1C : AA {
    //     A = AA(1),
    //     B = AA(2)
    // }

    // TE1C te1c;

    // writefln("te1c = %s", te1c.a);
}

