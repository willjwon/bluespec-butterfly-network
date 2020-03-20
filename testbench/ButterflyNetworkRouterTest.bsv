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

import ButterflyNetworkRouter::*;



Bit#(32) maxCycle = 100;


(* synthesize *)
module mkButterflyNetworkRouterTest();
    // Components
    let butterflyNetworkRouter <- mkButterflyNetworkRouter;

    // Benchmarks
    Reg#(Bit#(32)) cycle <- mkReg(0);

    // Run simulation
    rule runSimulation;
        cycle <= cycle + 1;
    endrule

    rule finishSimulation if (cycle >= maxCycle);
        $display("Max cycle reached");
        $finish(0);
    endrule

    // Test cases
    rule putLeftToLeft if (cycle == 0);
        let flit = Flit{payload: 1, destinationAddress: 8'b00000000};
        butterflyNetworkRouter.left.put(flit);
    endrule

    rule getLeftToLeft if (cycle == 1);
        let flit <- butterflyNetworkRouter.left.get;
        dynamicAssert(flit.payload == 1, "Should be 1");
    endrule

    rule putRightToLeft if (cycle == 2);
        let flit = Flit{payload: 2, destinationAddress: 8'b00000000};
        butterflyNetworkRouter.right.put(flit);
    endrule

    rule getRightToLeft if (cycle == 3);
        let flit <- butterflyNetworkRouter.left.get;
        dynamicAssert(flit.payload == 2, "Should be 2");
    endrule

    rule putCrossing if (cycle == 4);
        butterflyNetworkRouter.left.put(Flit{payload: 4, destinationAddress: 8'b10000000});
        butterflyNetworkRouter.right.put(Flit{payload: 7, destinationAddress: 8'b00000000});
    endrule
    
    rule getCrossing if (cycle == 5);
        let leftFlit <- butterflyNetworkRouter.left.get;
        dynamicAssert(leftFlit.payload == 7, "Should be 7");

        let rightFlit <- butterflyNetworkRouter.right.get;
        dynamicAssert(rightFlit.payload == 4, "Should be 4");
    endrule
endmodule
