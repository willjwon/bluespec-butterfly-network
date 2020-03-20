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

interface ButterflyNetworkRouter;
    interface Vector#(2, ButterflyNetworkRouterIngressPort) ingressPort;
    interface Vector#(2, ButterflyNetworkRouterEgressPort) egressPort;
endinterface


(* synthesize *)
module mkButterflyNetworkRouter(ButterflyNetworkRouter);
    /**
        Router for butterfly networt
        This would work as 2x2 crossbar
        
        This module assumes entering 2 inputs are already arbitrated (i.e., not requesting same output port)
    **/

    // Componenets
    // Fifos
    Vector#(2, Fifo#(1, Flit)) ingressFlits <- replicateM(mkBypassFifo);
    Vector#(2, Fifo#(1, Flit)) egressFlits <- replicateM(mkBypassFifo);

    
    // Rules
    rule forwardBothFlit if (ingressFlits[0].notEmpty && ingressFlits[1].notEmpty);
        // Assumption: already arbitrated
        let flit0 = ingressFlits[0].first;
        ingressFlits[0].deq;

        let flit1 = ingressFlits[1].first;
        ingressFlits[1].deq;

        // Crossing check
        let notCrossing = msb(flit0.destinationAddress) == 0;

        // Address modification
        flit0.destinationAddress = flit0.destinationAddress << 1;
        flit1.destinationAddress = flit1.destinationAddress << 1;

        // Forwarding
        if (notCrossing) begin
            egressFlits[0].enq(flit0);
            egressFlits[1].enq(flit1);
        end else begin
            // left to right
            egressFlits[1].enq(flit0);
            egressFlits[0].enq(flit1);
        end
    endrule

    rule forwardFlit0 if (ingressFlits[0].notEmpty && !ingressFlits[1].notEmpty);
        let flit0 = ingressFlits[0].first;
        ingressFlits[0].deq;

        // Crossing check
        let notCrossing = msb(flit0.destinationAddress) == 0;

        // Address modification
        flit0.destinationAddress = flit0.destinationAddress << 1;

        // Forwarding
        if (notCrossing) begin
            egressFlits[0].enq(flit0);
        end else begin
            // Crossing
            egressFlits[1].enq(flit0);
        end
    endrule

    rule forwardFlit1 if (!ingressFlits[0].notEmpty && ingressFlits[1].notEmpty);
        let flit1 = ingressFlits[1].first;
        ingressFlits[1].deq;

        // Crossing check
        let notCrossing = msb(flit1.destinationAddress) == 1;

        // Address modification
        flit1.destinationAddress = flit1.destinationAddress << 1;

        // Forwarding
        if (notCrossing) begin
            egressFlits[1].enq(flit1);
        end else begin
            egressFlits[0].enq(flit1);
        end
    endrule


    // Interfaces
    Vector#(2, ButterflyNetworkRouterIngressPort) ingressPortDefinition;
    for (Integer i = 0; i < 2; i = i + 1) begin
        ingressPortDefinition[i] = interface ButterflyNetworkRouterIngressPort
            method Action put(Flit flit);
                ingressFlits[i].enq(flit);
            endmethod
        endinterface;
        
    end

    Vector#(2, ButterflyNetworkRouterEgressPort) egressPortDefinition;
    for (Integer i = 0; i < 2; i = i + 1) begin
        egressPortDefinition[i] = interface ButterflyNetworkRouterEgressPort
            method ActionValue#(Flit) get;
                egressFlits[i].deq;
                return egressFlits[i].first;
            endmethod
        endinterface;
    end

    interface ingressPort = ingressPortDefinition;
    interface egressPort = egressPortDefinition;
endmodule
