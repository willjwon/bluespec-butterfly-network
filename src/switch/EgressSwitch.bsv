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

import Fifo::*;
import Vector::*;


interface EgressSwitchIngressPort#(type addressType, type payloadType);
    method Action put(Tuple2#(addressType, payloadType) flit);
endinterface

interface EgressSwitchEgressPort#(type payloadType);
    method ActionValue#(payloadType) get;
endinterface

interface EgressSwitch#(type addressType, type payloadType);
    interface Vector#(2, EgressSwitchIngressPort#(addressType, payloadType)) ingressPort;
    interface EgressSwitchEgressPort#(payloadType) egressPort;
endinterface


module mkEgressSwitch(EgressSwitch#(addressType, payloadType)) provisos (
    Bits#(addressType, addressTypeBitLength),
    Bitwise#(addressType),
    Bits#(payloadType, payloadTypeBitLength),
    Alias#(Tuple2#(addressType, payloadType), flitType)
);
    /**
        Router for butterfly networt
        This would work as 2x1 crossbar (2 input port, 1 output port)
        
        This module assumes entering 2 inputs are already arbitrated (i.e., only 1 between 2 receives a flit).
    **/

    // Componenets
    // Fifos
`ifdef pipelined
    Vector#(2, Fifo#(1, flitType)) ingressFlits <- replicateM(mkPipelineFifo);
`else
    Vector#(2, Fifo#(1, flitType)) ingressFlits <- replicateM(mkBypassFifo);
`endif
    Fifo#(1, payloadType) egressFlit <- mkBypassFifo;

    
    // Rules
    rule forwardFlit0 if (ingressFlits[0].notEmpty && !ingressFlits[1].notEmpty);
        egressFlit.enq(tpl_2(ingressFlits[0].first));
        ingressFlits[0].deq;
    endrule

    rule forwardFlit1 if (!ingressFlits[0].notEmpty && ingressFlits[1].notEmpty);
        egressFlit.enq(tpl_2(ingressFlits[1].first));
        ingressFlits[1].deq;
    endrule


    // Interfaces
    Vector#(2, EgressSwitchIngressPort#(addressType, payloadType)) ingressPortDefinition;
    for (Integer i = 0; i < 2; i = i + 1) begin
        ingressPortDefinition[i] = interface EgressSwitchIngressPort#(addressType, payloadType)
            method Action put(Tuple2#(addressType, payloadType) flit);
                ingressFlits[i].enq(flit);
            endmethod
        endinterface;    
    end

    interface ingressPort = ingressPortDefinition;

    interface egressPort = interface EgressSwitchEgressPort#(payloadType)
        method ActionValue#(payloadType) get;
            egressFlit.deq;
            return egressFlit.first;
        endmethod
    endinterface;
endmodule
