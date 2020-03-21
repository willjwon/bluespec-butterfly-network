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
import Vector::*;

import ButterflyNetworkType::*;


interface ButterflyNetworkRouterIngressPort;
    method Action put(Flit flit);
endinterface

interface ButterflyNetworkRouterEgressPort;
    method ActionValue#(Flit) get;
endinterface

interface ButterflyNetworkIngressRouter;
    interface ButterflyNetworkRouterIngressPort ingressPort;
    interface Vector#(2, ButterflyNetworkRouterEgressPort) egressPort;
endinterface


(* synthesize *)
module mkButterflyNetworkIngressRouter(ButterflyNetworkIngressRouter);
    /**
        Router for butterfly networt
        This would work as 1x2 crossbar (1-input, 2-output)
    **/

    // Componenets
    // Fifos
    Fifo#(1, Flit) ingressFlit <- mkBypassFifo;
`ifdef pipelined
    Vector#(2, Fifo#(1, Flit)) egressFlits <- replicateM(mkPipelineFifo);
`else
    Vector#(2, Fifo#(1, Flit)) egressFlits <- replicateM(mkBypassFifo);
`endif

    
    // Rules
    rule forwardFlit if (ingressFlit.notEmpty);
        let flit = ingressFlit.first;
        ingressFlit.deq;

        // Crossing check
        let towardsPort0 = msb(flit.destinationAddress) == 0;

        // Address modification
        flit.destinationAddress = flit.destinationAddress << 1;

        // Forwarding
        if (towardsPort0) begin
            egressFlits[0].enq(flit);
        end else begin
            egressFlits[1].enq(flit);
        end
    endrule


    // Interfaces
    Vector#(2, ButterflyNetworkRouterEgressPort) egressPortDefinition;
    for (Integer i = 0; i < 2; i = i + 1) begin
        egressPortDefinition[i] = interface ButterflyNetworkRouterEgressPort
            method ActionValue#(Flit) get;
                egressFlits[i].deq;
                return egressFlits[i].first;
            endmethod
        endinterface;
    end

    interface ingressPort = interface ButterflyNetworkRouterIngressPort
        method Action put(Flit flit);
            ingressFlit.enq(flit);
        endmethod
    endinterface;        

    interface egressPort = egressPortDefinition;
endmodule
