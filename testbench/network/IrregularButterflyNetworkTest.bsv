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
import IrregularButterflyNetwork::*;


Bit#(32) maxCycle = 1000;


(* synthesize *)
module mkIrregularButterflyNetworkTest();
    // UUT
    IrregularButterflyNetwork#(16, 4, Bit#(TLog#(4)), Bit#(32)) irregularButterflyNetwork <- mkIrregularButterflyNetwork;

    // Benchmarks
    Reg#(Bit#(32)) cycle <- mkReg(0);

    // Run simulation
    rule runSimulation;
        cycle <= cycle + 1;
    endrule

    rule finishSimulation if (cycle >= maxCycle);
        $display("Simulation finished at cycle %d.", cycle);
        $finish(0);
    endrule

    // // test cases
    rule put1 if (cycle == 3);
        irregularButterflyNetwork.ingressPort[6].put(2, 32);
    endrule

    rule put2 if (cycle == 4);
        irregularButterflyNetwork.ingressPort[0].put(0, 40);
        irregularButterflyNetwork.ingressPort[15].put(1, 41);
    endrule

    rule put3 if (cycle == 5);
        irregularButterflyNetwork.ingressPort[0].put(3, 53);
        irregularButterflyNetwork.ingressPort[3].put(2, 52);
        irregularButterflyNetwork.ingressPort[7].put(1, 51);
        irregularButterflyNetwork.ingressPort[15].put(0, 50);
    endrule

    for (Integer i = 0; i < 4; i = i + 1) begin
        rule printReceived;
            let receivedValue <- irregularButterflyNetwork.egressPort[i].get;
            $display("[Cycle %d, Dest %d]: %d received.", cycle, i, receivedValue);
        endrule
    end
endmodule
