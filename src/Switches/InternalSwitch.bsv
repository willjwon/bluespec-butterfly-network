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


interface InternalSwitchIngressPort#(type addressType, type payloadType);
    method Action put(Tuple2#(addressType, payloadType) flit);
endinterface

interface InternalSwitchEgressPort#(type addressType, type payloadType);
    method ActionValue#(Tuple2#(addressType, payloadType)) get;
endinterface

interface InternalSwitch#(type addressType, type payloadType);
    interface Vector#(2, InternalSwitchIngressPort#(addressType, payloadType)) ingressPort;
    interface Vector#(2, InternalSwitchEgressPort#(addressType, payloadType)) egressPort;
endinterface


module mkInternalSwitch(InternalSwitch#(addressType, payloadType)) provisos (
    Bits#(addressType, addressTypeBitLength),
    Bitwise#(addressType),
    Bits#(payloadType, payloadTypeBitLength),
    Alias#(Tuple2#(addressType, payloadType), flitType)
);
    /**
        Router for butterfly networt
        This would work as 2x2 crossbar
        
        This module assumes entering 2 inputs are already arbitrated (i.e., not requesting same output port)
    **/

    // Componenets
    // Fifos
    Vector#(2, Fifo#(1, flitType)) ingressFlits <- replicateM(mkBypassFifo);
`ifdef pipelined
    Vector#(2, Fifo#(1, flitType)) egressFlits <- replicateM(mkPipelineFifo);
`else
    Vector#(2, Fifo#(1, flitType)) egressFlits <- replicateM(mkBypassFifo);
`endif

    
    // Rules
    rule forwardBothFlit if (ingressFlits[0].notEmpty && ingressFlits[1].notEmpty);
        // Assumption: already arbitrated
        match {.destinationAddress0, .payload0} = ingressFlits[0].first;
        ingressFlits[0].deq;

        match {.destinationAddress1, .payload1} = ingressFlits[1].first;
        ingressFlits[1].deq;

        // Crossing check
        let notCrossing = msb(destinationAddress0) == 0;

        // Address modification
        flitType updatedFlit0 = tuple2(destinationAddress0 << 1, payload0);
        flitType updatedFlit1 = tuple2(destinationAddress1 << 1, payload1);

        // Forwarding
        if (notCrossing) begin
            egressFlits[0].enq(updatedFlit0);
            egressFlits[1].enq(updatedFlit1);
        end else begin
            // left to right
            egressFlits[0].enq(updatedFlit1);
            egressFlits[1].enq(updatedFlit0);
        end
    endrule

    rule forwardFlit0 if (ingressFlits[0].notEmpty && !ingressFlits[1].notEmpty);
        match {.destinationAddress0, .payload0} = ingressFlits[0].first;
        ingressFlits[0].deq;

        // Crossing check
        let notCrossing = msb(destinationAddress0) == 0;

        // Address modification
        flitType updatedFlit0 = tuple2(destinationAddress0 << 1, payload0);

        // Forwarding
        if (notCrossing) begin
            egressFlits[0].enq(updatedFlit0);
        end else begin
            // Crossing
            egressFlits[1].enq(updatedFlit0);
        end
    endrule

    rule forwardFlit1 if (!ingressFlits[0].notEmpty && ingressFlits[1].notEmpty);
        match {.destinationAddress1, .payload1} = ingressFlits[1].first;
        ingressFlits[1].deq;

        // Crossing check
        let crossing = msb(destinationAddress1) == 0;

        // Address modification
        flitType updatedFlit1 = tuple2(destinationAddress1 << 1, payload1);

        // Forwarding
        if (crossing) begin
            // Crossing
            egressFlits[0].enq(updatedFlit1);
        end else begin
            egressFlits[1].enq(updatedFlit1);
        end
    endrule


    // Interfaces
    Vector#(2, InternalSwitchIngressPort#(addressType, payloadType)) ingressPortDefinition;
    for (Integer i = 0; i < 2; i = i + 1) begin
        ingressPortDefinition[i] = interface InternalSwitchIngressPort#(addressType, payloadType);
            method Action put(Tuple2#(addressType, payloadType) flit);
                ingressFlits[i].enq(flit);
            endmethod
        endinterface;
    end

    Vector#(2, InternalSwitchEgressPort#(addressType, payloadType)) egressPortDefinition;
    for (Integer i = 0; i < 2; i = i + 1) begin
        egressPortDefinition[i] = interface InternalSwitchEgressPort#(addressType, payloadType);
            method ActionValue#(Tuple2#(addressType, payloadType)) get;
                egressFlits[i].deq;
                return egressFlits[i].first;
            endmethod
        endinterface;
    end

    interface ingressPort = ingressPortDefinition;
    interface egressPort = egressPortDefinition;
endmodule
