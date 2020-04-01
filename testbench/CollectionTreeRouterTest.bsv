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


import CollectionTreeRouter::*;


Bit#(32) maxCycle = 100;


(* synthesize *)
module mkCollectionTreeRouterTest();
    // uut
    CollectionTreeRouter#(Bit#(32)) collectionTreeRouter <- mkCollectionTreeRouter;

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
    rule forwardLeft if (cycle == 0);
        collectionTreeRouter.ingressPort[0].put(3);
    endrule

    rule fetchLeft if (cycle == 1);
        let result <- collectionTreeRouter.egressPort.get;
        dynamicAssert(result == 3, "Should be 3");
    endrule

    rule forwardRight if (cycle == 2);
        collectionTreeRouter.ingressPort[0].put(30);
    endrule

    rule fetchRight if (cycle == 3);
        let result <- collectionTreeRouter.egressPort.get;
        dynamicAssert(result == 30, "Should be 30");
    endrule
endmodule
