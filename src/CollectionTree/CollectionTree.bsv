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
import Connectable::*;

import CollectionTreeRouter::*;


interface CollectionTreeIngressPort#(type dataType);
    method Action put(dataType data);
endinterface

interface CollectionTreeEgressPort#(type dataType);
    method ActionValue#(dataType) get;
endinterface

interface CollectionTree#(numeric type ingressPortsCount, type dataType);
    interface Vector#(ingressPortsCount, CollectionTreeIngressPort#(dataType)) ingressPort;
    interface CollectionTreeEgressPort#(dataType) egressPort;
endinterface


module mkCollectionTree(CollectionTree#(ingressPortsCount, dataType))
provisos (Bits#(dataType, dataTypeBitwidth));
    /**
    * n-to-1 collection router
    * Invariant: only 1 ingressPort calls put method.
    */

    //
    // Assume: 8-to-1
    // Router architecture:
    //
    //    egress
    //       |
    //       0
    //    1     2      
    //   3 4   5 6
    //  /| |\ /| |\
    //    ingress
    // 
    // 1. #routers = (ingressPortsCount - 1)
    // 2. Leaf nodes = [ (ingressPortsCount / 2) - 1, ingressPortsCount - 1 )
    // 3. Internal nodes = [ 0, (ingressPortsCount / 2) - 1 )
    //
    // Connection:
    //     Internal node i: two leaves (2i + 1), (2i + 2)
    //         connect - (2i+1).egress, i.ingress[0]
    //                 - (2i+2).egress, i.ingress[1]
    //
    //      Leaf nodes:
    //          connect - ingress[ 0, ingressPortsCount / 2), leaves[i].ingress[0]
    //                  - ingress[ (ingressPortsCount / 2), ingressPortsCount ), leaves[i].ingress[1]
    //


    // Submodule
    Vector#(TSub#(ingressPortsCount, 1), CollectionTreeRouter#(dataType)) routers <- replicateM(mkCollectionTreeRouter);


    // Numerical value
    Integer leafNodeStartIndex = (valueOf(ingressPortsCount) / 2) - 1;
    Integer leafNodesCount = valueOf(ingressPortsCount) / 2;

    // Combinational logic
    for (Integer i = 0; i < leafNodeStartIndex; i = i + 1) begin
        Integer leftChildIndex = (2 * i) + 1;
        Integer rightChildIndex = (2 * i) + 2;
        mkConnection(routers[leftChildIndex].egressPort.get, routers[i].ingressPort[0].put);
        mkConnection(routers[rightChildIndex].egressPort.get, routers[i].ingressPort[1].put);
    end


    // Interface
    Vector#(ingressPortsCount, CollectionTreeIngressPort#(dataType)) ingressPortDefinition = newVector;

    for (Integer i = 0; i < leafNodesCount; i = i + 1) begin
        // connect to ingressPort 0
        Integer leafNodeIndex = leafNodeStartIndex + i;
        
        ingressPortDefinition[i] = interface CollectionTreeIngressPort#(dataType)
            method Action put(dataType data);    
                routers[leafNodeIndex].ingressPort[0].put(data);
            endmethod
        endinterface;
    end

    for (Integer i = 0; i < leafNodesCount; i = i + 1) begin
        // connect to ingressPort 1
        Integer ingressPortIndex = leafNodesCount + i;
        Integer leafNodeIndex = leafNodeStartIndex + i;
        
        ingressPortDefinition[ingressPortIndex] = interface CollectionTreeIngressPort#(dataType)
            method Action put(dataType data);    
                routers[leafNodeIndex].ingressPort[1].put(data);
            endmethod
        endinterface;
    end

    interface ingressPort = ingressPortDefinition;

    interface egressPort = interface CollectionTreeEgressPort#(dataType)
        method ActionValue#(dataType) get;
            let data <- routers[0].egressPort.get;
            return data;
        endmethod
    endinterface;

endmodule
