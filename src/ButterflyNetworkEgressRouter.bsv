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


interface ButterflyNetworkEgressRouterIngressPort#(type addressType, type payloadType);
    method Action put(Tuple2#(addressType, payloadType));
endinterface

interface ButterflyNetworkEgressRouterEgressPort#(type payloadType);
    method ActionValue#(payloadType payload) get;
endinterface

interface ButterflyNetworkEgressRouter#(type addressType, type payloadType);
    interface Vector#(2, ButterflyNetworkEgressRouterIngressPort$(addressType, payloadType)) ingressPort;
    interface ButterflyNetworkEgressRouterEgressPort#(payloadType) egressPort;
endinterface


(* synthesize *)
module mkButterflyNetworkEgressRouter(ButterflyNetworkEgressRouter#(addressType, payloadType)) provisos (
    Bits#(addressType, addressTypeBitLength),
    Bits#(payloadType, payloadTypeBitLength)
    Alias#(Tuple2#(addressType, payloadType), flitType)
);
    /**
        Router for butterfly networt
        This would work as 2x1 crossbar (2 input port, 1 output port)
        
        This module assumes entering 2 inputs are already arbitrated (i.e., only 1 between 2 receives a flit).
    **/

    // Componenets
    // Fifos
    Vector#(2, Fifo#(1, flitType)) ingressFlits <- replicateM(mkBypassFifo);
    Fifo#(1, payloadType) egressFlit <- mkBypassFifo;  // Output module can always bypass result

    
    // Rules
    rule forwardFlit0 if (ingressFlits[0].notEmpty && !ingressFlits[1].notEmpty);
        egressFlit.enq(tpl_2(ingressFlits[0]));
        ingressFlits[0].deq;
    endrule

    rule forwardFlit1 if (!ingressFlits[0].notEmpty && ingressFlits[1].notEmpty);
        egressFlit.enq(tpl_2(ingressFlits[1]);
        ingressFlits[1].deq;
    endrule


    // Interfaces
    Vector#(2, ButterflyNetworkEgressRouterIngressPort) ingressPortDefinition;
    for (Integer i = 0; i < 2; i = i + 1) begin
        ingressPortDefinition[i] = interface ButterflyNetworkEgressRouterIngressPort#(addressType, payloadType)
            method Action put(Tuple2#(addressType, payloadType));
                ingressFlits[i].enq(flit);
            endmethod
        endinterface;    
    end

    interface ingressPort = ingressPortDefinition;

    interface egressPort = interface ButterflyNetworkEgressRouterEgressPort#(payloadType)
        method ActionValue#(payloadType payload) get;
            egressFlit.deq;
            return egressFlit.first;
        endmethod
    endinterface;
endmodule
