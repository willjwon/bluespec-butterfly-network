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
import IngressSwitch::*;


Bit#(32) maxCycle = 100;


(* synthesize *)
module mkIngressSwitchTest();
    // Components
    IngressSwitch#(Bit#(3), Bit#(32)) ingressSwitch <- mkIngressSwitch;

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
    rule putToPort0 if (cycle == 0);
        ingressSwitch.ingressPort.put(3'b011, 1);
    endrule

    rule getPort0 if (cycle == 1);
        $display("test 1");

        let flit <- ingressSwitch.egressPort[0].get;
        dynamicAssert(tpl_2(flit) == 1, "Should be 1");
        dynamicAssert(tpl_1(flit) == 3'b110, "Address should be shifted left by 1");
    endrule

    rule putToPort1 if (cycle == 10);
        ingressSwitch.ingressPort.put(3'b111, 5);
    endrule

    rule getPort1 if (cycle == 15);
        $display("test 2");

        let flit <- ingressSwitch.egressPort[1].get;
        dynamicAssert(tpl_2(flit) == 5, "Should be 5");
        dynamicAssert(tpl_1(flit) == 3'b110, "Address should be shifted left by 1");
    endrule
endmodule
