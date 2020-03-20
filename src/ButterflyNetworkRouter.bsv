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


import Fifo::*;

import ButterflyNetworkType::*;


interface ButterflyNetworkRouterData;
    method Action put(Flit flit);
    method ActionValue#(Flit) get;
endinterface

interface ButterflyNetworkRouter;
    interface ButterflyNetworkRouterData left;
    interface ButterflyNetworkRouterData right;
endinterface


(* synthesize *)
module mkButterflyNetworkRouter(ButterflyNetworkRouter);
    /**
        Router for butterfly networt
        This would work as 2x2 crossbar
        
        This module assumes entering 2 inputs are already arbitrated (i.e., not requesting same output port)
    **/

    // Componenets
    // Ingress Fifos
    Fifo#(1, Flit) leftIngressFlit <- mkBypassFifo;
    Fifo#(1, Flit) rightIngressFlit <- mkBypassFifo;

    // Egress fifos
    Fifo#(1, Flit) leftEgressFlit <- mkPipelineFifo;
    Fifo#(1, Flit) rightEgressFlit <- mkPipelineFifo;

    
    // Rules
    rule forwardBoth if (leftIngressFlit.notEmpty && rightIngressFlit.notEmpty);
        // Assumption: already arbitrated
        let leftFlit = leftIngressFlit.first;
        leftIngressFlit.deq;

        let rightFlit = rightIngressFlit.first;
        rightIngressFlit.deq;

        // Address change
        let leftToLeft = msb(leftFlit.destinationAddress) == 0;
        leftFlit.destinationAddress = leftFlit.destinationAddress << 1;
        rightFlit.destinationAddress = rightFlit.destinationAddress << 1;

        if (leftToLeft) begin
            leftEgressFlit.enq(leftFlit);
            rightEgressFlit.enq(rightFlit);
        end else begin
            // left to right
            rightEgressFlit.enq(leftFlit);
            leftEgressFlit.enq(rightFlit);
        end
    endrule

    rule forwardLeft if (leftIngressFlit.notEmpty && !rightIngressFlit.notEmpty);
        let leftFlit = leftIngressFlit.first;
        leftIngressFlit.deq;

        // Address change
        let leftToLeft = msb(leftFlit.destinationAddress) == 0;
        leftFlit.destinationAddress = leftFlit.destinationAddress << 1;

        if (leftToLeft) begin
            leftEgressFlit.enq(leftFlit);
        end else begin
            // left to right
            rightEgressFlit.enq(leftFlit);
        end
    endrule

    rule forwardRight if (!leftIngressFlit.notEmpty && rightIngressFlit.notEmpty);
        let rightFlit = rightIngressFlit.first;
        rightIngressFlit.deq;

        // Address change
        let rightToLeft = msb(rightFlit.destinationAddress) == 0;
        rightFlit.destinationAddress = rightFlit.destinationAddress << 1;

        if (rightToLeft) begin
            leftEgressFlit.enq(rightFlit);
        end else begin
            // right to right
            rightEgressFlit.enq(rightFlit);
        end
    endrule


    // Interfaces
    interface left = interface ButterflyNetworkRouterData
        method Action put(Flit flit);
            leftIngressFlit.enq(flit);
        endmethod

        method ActionValue#(Flit) get;
            leftEgressFlit.deq;
            return leftEgressFlit.first;
        endmethod
    endinterface;

    interface right = interface ButterflyNetworkRouterData
        method Action put(Flit flit);
            rightIngressFlit.enq(flit);
        endmethod

        method ActionValue#(Flit) get;
            rightEgressFlit.deq;
            return rightEgressFlit.first;
        endmethod
    endinterface;
endmodule
