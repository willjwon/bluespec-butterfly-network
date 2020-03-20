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

typedef struct {
    Bit#(32) payload;
    Bit#(8) destinationAddress;
} Flit deriving (Bits, Eq);


import Fifo::*;


interface ButterflyNetworkRouterData;
    method Action put(Flit data);
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
    // Input fifos
    Fifo#(1, Flit) leftInputFifo <- mkBypassFifo;
    Fifo#(1, Flit) rightInputFifo <- mkBypassFifo;

    // Output fifos
    Fifo#(1, Flit) leftOutputFifo <- mkPipelineFifo;
    Fifo#(1, Flit) rightOutputFifo <- mkPipelineFifo;


    // Rules
    rule forwardBoth if (leftInputFifo.notEmpty && rightInputFifo.notEmpty);
        let leftFlit = leftInputFifo.first;
        leftInputFifo.deq;

        let rightFlit = rightInputFifo.first;
        rightInputFifo.deq;

        // Assumption: already arbitrated
        if (msb(leftFlit.destinationAddress) == 0) begin
            leftOutputFifo.enq(leftFlit);
            rightOutputFifo.enq(rightFlit);
        end else begin
            rightOutputFifo.enq(leftFlit);
            leftOutputFifo.enq(rightFlit);
        end
    endrule

    rule forwardLeft if (leftInputFifo.notEmpty && !rightInputFifo.notEmpty);
        let leftFlit = leftInputFifo.first;
        leftInputFifo.deq;

        if (msb(leftFlit.destinationAddress) == 0) begin
            leftOutputFifo.enq(leftFlit);
        end else begin
            rightOutputFifo.enq(leftFlit);
        end

    endrule

    rule forwardRight if (!leftInputFifo.notEmpty && rightInputFifo.notEmpty);
        let rightFlit = rightInputFifo.first;
        rightInputFifo.deq;

        if (msb(rightFlit.destinationAddress) == 0) begin
            leftOutputFifo.enq(rightFlit);
        end else begin
            rightOutputFifo.enq(rightFlit);
        end
    endrule


    // Interfaces
    interface left = interface ButterflyNetworkRouterData
        method Action put(Flit data);
            leftInputFifo.enq(data);
        endmethod

        method ActionValue#(Flit) get;
            leftOutputFifo.deq;
            return leftOutputFifo.first;
        endmethod
    endinterface;

    interface right = interface ButterflyNetworkRouterData
        method Action put(Flit data);
            rightInputFifo.enq(data);
        endmethod

        method ActionValue#(Flit) get;
            rightOutputFifo.deq;
            return rightOutputFifo.first;
        endmethod
    endinterface;
endmodule
