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


import Vector::*;
import Fifo::*;


interface CollectionTreeRouterIngressPort#(type dataType);
    method Action put(dataType data);
endinterface

interface CollectionTreeRouterEgressPort#(type dataType);
    method ActionValue#(dataType) get;
endinterface

interface CollectionTreeRouter#(type dataType);
    interface Vector#(2, CollectionTreeRouterIngressPort#(dataType)) ingressPort;
    interface CollectionTreeRouterEgressPort#(dataType) egressPort;
endinterface


module mkCollectionTreeRouter(CollectionTreeRouter#(dataType))
provisos (Bits#(dataType, dataTypeBitwidth));
    /**
    * 2-to-1 collection router
    * Invariant: only 1 ingressPort calls put method.
    */

    // Submodule
    Vector#(2, Fifo#(1, dataType)) ingressFlits <- replicateM(mkBypassFifo);

`ifdef pipelined
    Fifo#(1, dataType) egressFlit <- mkPipelineFifo;
`else
    Fifo#(1, dataType) egressFlit <- mkBypassFifo;
`endif


    // Rule
    rule forwardPort0 if (ingressFlits[0].notEmpty && !ingressFlits[1].notEmpty);
        egressFlit.enq(ingressFlits[0].first);
        ingressFlits[0].deq;
    endrule

    rule forwardPort1 if (!ingressFlits[0].notEmpty && ingressFlits[1].notEmpty);
        egressFlit.enq(ingressFlits[1].first);
        ingressFlits[1].deq;
    endrule


    // Interface
    Vector#(2, CollectionTreeRouterIngressPort#(dataType)) ingressPortDefinition = newVector;
    for (Integer i = 0; i < 2; i = i + 1) begin
        ingressPortDefinition[i] = interface CollectionTreeRouterIngressPort
            method Action put(dataType data);
                ingressFlits[i].enq(data);
            endmethod
        endinterface;
    end

    interface ingressPort = ingressPortDefinition;

    interface egressPort = interface CollectionTreeRouterEgressPort#(dataType)
        method ActionValue#(dataType) get;
            egressFlit.deq;
            return egressFlit.first;
        endmethod
    endinterface;
endmodule
