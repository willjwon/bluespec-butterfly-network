// MIT License

// Copyright (c) 2020 William Won (william.won@gatech.edu)

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


import Assert::*;


import CollectionTree::*;


Bit#(32) maxCycle = 100;


(* synthesize *)
module mkCollectionTreeTest();
    // uut
    CollectionTree#(8, Bit#(32)) collectionTree <- mkCollectionTree;

    // cycle
    Reg#(Bit#(32)) cycle <- mkReg(0);

    // run simulation
    rule runSimulation;
        cycle <= cycle + 1;
    endrule

    rule finishSimulation if (cycle >= maxCycle);
        $display("Simulation finished at cycle %d.", cycle);
        $finish(0);
    endrule

    // test cases
    rule putPort0 if (cycle == 0);
        collectionTree.ingressPort[0].put(3);
    endrule

    rule getPort0 if (cycle == 1);
        $display("Test 1");
        let result <- collectionTree.egressPort.get;
        dynamicAssert(result == 3, "Should be 3");
    endrule

    rule putPort7 if (cycle == 2);
        collectionTree.ingressPort[7].put(7);
    endrule

    rule getPort7 if (cycle == 3);
        $display("Test 2");
        let result <- collectionTree.egressPort.get;
        dynamicAssert(result == 7, "Should be 7");
    endrule
endmodule
