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

import ButterflyNetworkType::*;
import ButterflyNetworkInternalRouter::*;


Bit#(32) maxCycle = 100;


(* synthesize *)
module mkButterflyNetworkInternalRouterTest();
    // Components
    ButterflyNetworkInternalRouter#(Bit#(3), Bit#(32)) butterflyNetworkRouter <- mkButterflyNetworkInternalRouter;

    // Benchmarks
    Reg#(Bit#(32)) cycle <- mkReg(0);

    // Run simulation
    rule runSimulation;
        cycle <= cycle + 1;
    endrule

    rule finishSimulation if (cycle >= maxCycle);
        $display("Simulation finished without assertion failure.");
        $finish(0);
    endrule

    // Test cases
    rule putLeftToLeft if (cycle == 0);
        butterflyNetworkRouter.ingressPort[0].put(Flit{payload: 1, destinationAddress: 3'b011});
    endrule

    rule getLeftToLeft if (cycle == 1);
        let flit <- butterflyNetworkRouter.egressPort[0].get;
        dynamicAssert(flit.payload == 1, "Should be 1");
        dynamicAssert(tpl_1(flit) == 3'b110, "Address should be shifted left by 1");
    endrule

    rule putRightToLeft if (cycle == 2);
        butterflyNetworkRouter.ingressPort[1].put(Flit{payload: 5, destinationAddress: 3'b010});
    endrule

    rule getRightToLeft if (cycle == 3);
        let flit <- butterflyNetworkRouter.egressPort[1].get;
        dynamicAssert(flit.payload == 5, "Should be 5");
        dynamicAssert(tpl_1(flit) == 3'b100, "Address should be shifted left by 1");
    endrule

    rule putCrossing if (cycle == 4);
        butterflyNetworkRouter.ingressPort[0].put(Flit{payload: 7, destinationAddress: 3'b101});
        butterflyNetworkRouter.ingressPort[1].put(Flit{payload: 11, destinationAddress: 3'b010});
    endrule
    
    rule getCrossing if (cycle == 5);
        let leftFlit <- butterflyNetworkRouter.egressPort[0].get;
        dynamicAssert(leftFlit.payload == 11, "Should be 11");
        dynamicAssert(lefttpl_1(flit) == 3'b100, "Address should be shifted left by 1");

        let rightFlit <- butterflyNetworkRouter.egressPort[1].get;
        dynamicAssert(rightFlit.payload == 7, "Should be 7");
        dynamicAssert(righttpl_1(flit) == 3'b010, "Address should be shifted left by 1");
    endrule
endmodule
