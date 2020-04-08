// MIT License

// Copyright (c) 2020 Synergy Lab | Georgia Institute of Technology
// Author: William Won (william.won@gatech.edu)

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

import ButterflyNetwork::*;


Bit#(32) maxCycle = 100;


(* synthesize *)
module mkButterflyNetworkTest();
    // Components
    ButterflyNetwork#(8, Bit#(TLog#(8)), Bit#(32)) butterflyNetwork <- mkButterflyNetwork;

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
        butterflyNetwork.ingressPort[0].put(3'd1, 0);
        butterflyNetwork.ingressPort[1].put(3'd0, 1);
        butterflyNetwork.ingressPort[2].put(3'd2, 2);
        butterflyNetwork.ingressPort[3].put(3'd7, 3);
        butterflyNetwork.ingressPort[4].put(3'd3, 4);
    endrule

    rule put1 if (cycle == 1);
        butterflyNetwork.ingressPort[0].put(3'd7, 10);
        butterflyNetwork.ingressPort[1].put(3'd6, 11);
        butterflyNetwork.ingressPort[2].put(3'd5, 12);
        butterflyNetwork.ingressPort[3].put(3'd4, 13);
        butterflyNetwork.ingressPort[4].put(3'd3, 14);
        butterflyNetwork.ingressPort[5].put(3'd2, 15);
        butterflyNetwork.ingressPort[6].put(3'd1, 16);
        butterflyNetwork.ingressPort[7].put(3'd0, 17);
    endrule

    for (Integer i = 0; i < valueOf(8); i = i + 1) begin
        rule printReceived;
            let receivedPayload <- butterflyNetwork.egressPort[i].get;
            $display("Cycle %d: Node %d received payload %d", cycle, i, receivedPayload);
        endrule
    end
endmodule
