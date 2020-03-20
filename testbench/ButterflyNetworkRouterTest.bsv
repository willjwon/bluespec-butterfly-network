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


typedef Bit#(32) Payload;
typedef Bit#(8) DestinationAddress;


(* synthesize *)
module mkButterflyNetworkRouterTest();
    // Components
    ButterflyNetworkRouter#(DestinationAddress, Payload) butterflyNetworkRouter <- mkButterflyNetworkRouter;

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
        butterflyNetworkRouter.left.put(8'b01000000, 1);
    endrule

    rule getLeftToLeft if (cycle == 1);
        let payload <- butterflyNetworkRouter.left.getPayload;
        let address <- butterflyNetworkRouter.left.getDestinationAddress;
        dynamicAssert(payload == 1, "Should be 1");
        dynamicAssert(address == 8'b10000000, "Address should be shifted left by 1");
    endrule

    rule putRightToLeft if (cycle == 2);
        butterflyNetworkRouter.right.put(8'b01100000, 5);
    endrule

    rule getRightToLeft if (cycle == 3);
        let payload <- butterflyNetworkRouter.left.getPayload;
        let address <- butterflyNetworkRouter.left.getDestinationAddress;
        dynamicAssert(payload == 5, "Should be 5");
        dynamicAssert(address == 8'b11000000, "Address should be shifted left by 1");
    endrule

    rule putCrossing if (cycle == 4);
        butterflyNetworkRouter.left.put(8'b10100000, 7);
        butterflyNetworkRouter.right.put(8'b01000001, 11);
    endrule
    
    rule getCrossing if (cycle == 5);
        let payloadLeft <- butterflyNetworkRouter.left.getPayload;
        let addressLeft <- butterflyNetworkRouter.left.getDestinationAddress;
        dynamicAssert(payloadLeft == 11, "Should be 11");
        dynamicAssert(addressLeft == 8'b10000010, "Address should be shifted left by 1");

        let payloadRight <- butterflyNetworkRouter.right.getPayload;
        let addressRight <- butterflyNetworkRouter.right.getDestinationAddress;
        dynamicAssert(payloadRight == 7, "Should be 7");
        dynamicAssert(addressRight == 8'b01000000, "Address should be shifted left by 1");
    endrule
endmodule
