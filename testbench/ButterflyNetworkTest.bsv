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
import ButterflyNetwork::*;


Bit#(32) maxCycle = 100;


typedef 4 NodesCount;


(* synthesize *)
module mkButterflyNetworkTest();
    // Components
    let butterflyNetwork <- mkButterflyNetwork;

    // Benchmarks
    Reg#(Bit#(32)) cycle <- mkReg(0);

    // Run simulation
    rule runSimulation;
        cycle <= cycle + 1;
    endrule

    rule finishSimulation if (cycle >= maxCycle);
        $display("Simulation finished.");
        $finish(0);
    endrule

    // Test cases
    rule put0 if (cycle == 0);
        butterflyNetwork.ingressPort[0].put(Flit{payload: 0, destinationAddress: 1});
        butterflyNetwork.ingressPort[1].put(Flit{payload: 1, destinationAddress: 0});
        butterflyNetwork.ingressPort[2].put(Flit{payload: 2, destinationAddress: 2});
        butterflyNetwork.ingressPort[3].put(Flit{payload: 3, destinationAddress: 7});
        butterflyNetwork.ingressPort[4].put(Flit{payload: 4, destinationAddress: 3});
    endrule

    rule put1 if (cycle == 1);
        butterflyNetwork.ingressPort[0].put(Flit{payload: 10, destinationAddress: 7});
        butterflyNetwork.ingressPort[1].put(Flit{payload: 11, destinationAddress: 6});
        butterflyNetwork.ingressPort[2].put(Flit{payload: 12, destinationAddress: 5});
        butterflyNetwork.ingressPort[3].put(Flit{payload: 13, destinationAddress: 4});
        butterflyNetwork.ingressPort[4].put(Flit{payload: 14, destinationAddress: 3});
        butterflyNetwork.ingressPort[5].put(Flit{payload: 15, destinationAddress: 2});
        butterflyNetwork.ingressPort[6].put(Flit{payload: 16, destinationAddress: 1});
        butterflyNetwork.ingressPort[7].put(Flit{payload: 17, destinationAddress: 0});
    endrule

    for (Integer i = 0; i < valueOf(TerminalNodesCount); i = i + 1) begin
        rule printReceived;
            let receivedFlit <- butterflyNetwork.egressPort[i].get;
            $display("Cycle %d: Node %d received payload %d", cycle, i, receivedFlit.payload);
        endrule
    end
endmodule
