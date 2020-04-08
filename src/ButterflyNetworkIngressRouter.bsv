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


interface ButterflyNetworkRouterIngressPort#(type addressType, type payloadType);
    method Action put(addressType destinationAddress, payloadType payload);
endinterface

interface ButterflyNetworkRouterEgressPort#(type addressType, type payloadType);
    method ActionValue#(Tuple2#(addressType, payloadType)) get;
endinterface

interface ButterflyNetworkIngressRouter#(type addressType, type payloadType);
    interface ButterflyNetworkRouterIngressPort#(addressType, payloadType) ingressPort;
    interface Vector#(2, ButterflyNetworkRouterEgressPort#(addressType, payloadType)) egressPort;
endinterface


module mkButterflyNetworkIngressRouter(ButterflyNetworkIngressRouter#(addressType, payloadType)) provisos (
    Bits#(addressType, addressTypeBitLength),
    Bitwise#(addressType),
    Bits#(payloadType, payloadTypeBitLength),
    Alias#(Tuple2#(addressType, payloadType), flitType)
);
    /**
        Router for butterfly networt
        This would work as 1x2 crossbar (1-input, 2-output)
    **/

    // Componenets
    // Fifos
    Fifo#(1, flitType) ingressFlit <- mkBypassFifo;
`ifdef pipelined
    Vector#(2, Fifo#(1, flitType)) egressFlits <- replicateM(mkPipelineFifo);
`else
    Vector#(2, Fifo#(1, flitType)) egressFlits <- replicateM(mkBypassFifo);
`endif

    
    // Rules
    rule forwardFlit if (ingressFlit.notEmpty);
        match {.destinationAddress, .payload} = ingressFlit.first;
        ingressFlit.deq;

        // Crossing check
        let towardsPort0 = msb(destinationAddress) == 0;

        // Address modification
        flitType updatedFlit = tuple2(destinationAddress << 1, payload);

        // Forwarding
        if (towardsPort0) begin
            egressFlits[0].enq(updatedFlit);
        end else begin
            egressFlits[1].enq(updatedFlit);
        end
    endrule


    // Interfaces
    Vector#(2, ButterflyNetworkRouterEgressPort#(addressType, payloadType)) egressPortDefinition;
    for (Integer i = 0; i < 2; i = i + 1) begin
        egressPortDefinition[i] = interface ButterflyNetworkRouterEgressPort#(addressType, payloadType)
            method ActionValue#(Tuple2#(addressType, payloadType)) get;
                egressFlits[i].deq;
                return egressFlits[i].first;
            endmethod
        endinterface;
    end

    interface ingressPort = interface ButterflyNetworkRouterIngressPort#(addressType, payloadType)
        method Action put(addressType destinationAddress, payloadType payload);
            ingressFlit.enq(tuple2(destinationAddress, payload));
        endmethod
    endinterface;        

    interface egressPort = egressPortDefinition;
endmodule
