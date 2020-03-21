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
import Connectable::*;

import ButterflyNetworkType::*;
import ButterflyNetworkIngressRouter::*;
import ButterflyNetworkInternalRouter::*;


interface ButterflyNetworkIngressPort;
    method Action put(Flit flit);
endinterface

interface ButterflyNetworkEgressPort;
    method ActionValue#(Flit) get;
endinterface

interface ButterflyNetwork;
    interface Vector#(TerminalNodesCount, ButterflyNetworkIngressPort) ingressPort;
    interface Vector#(TerminalNodesCount, ButterflyNetworkEgressPort) egressPort;
endinterface


(* synthesize *)
module mkButterflyNetwork(ButterflyNetwork);
    /**
        Regular butterfly topology
    **/

    // Components
    Vector#(TerminalNodesCount, ButterflyNetworkIngressRouter) ingressRouters <- replicateM(mkButterflyNetworkIngressRouter);
    Vector#(NetworkLevelsCount, Vector#(TerminalNodesCount, ButterflyNetworkInternalRouter)) internalRouters <- replicateM(replicateM(mkButterflyNetworkInternalRouter));


    // Combinational Logic
    // 1. For each networkLevel (1 through (NetworkLevlsCount - 1)):
    //      - would like to split into multiple crossing segments
    //      e.g., 
    //              o o o o o o o o
    //              |x| |x| |x| |x|
    //              o o o o o o o o   ( <- networkLevel)
    //      this shows segments=4 with nodesInSegments=2
    //
    // 2. Each routerID is composed of (segmentBase + routerOffset)
    //
    // 3. Computing which next router router[networkLevel][routerID] should be connected with:
    //      1) Diagonally, should jump (nodesInSegment/2) from routerOffset
    //           e.g., 
    //                        segmentBase
    //                     . . . . | . o . .
    //                    (. . . . | . . \ .)
    //                     . . . . | . . . o
    //             router[0][(4=segmentBase) + (1=routerOffset)]
    //             should be connected to router[1][(4=segmentBase) + (1=routerOffset) + (2=nodesInSegment/2)]
    //      2) But it should roll over when (routerOffset) + (nodesInSegment) > nodesInSegment
    //             therefore, should jump ((routerOffset + nodesInSegment / 2) % nodesInSegment)
    //      3) Therefore, destination: segmentBase + ((routerOffset + nodesInSegment / 2) % nodesInSegment)
    //
    //      4) It's trivial router[i][routerID] should also be connected to router[i + 1][routerID].
    //
    // 4. Connect egressPort0 to smaller destination routerID, egressPort1 to bigger destination routerID.
    //
    // 4. Connecting convention not to make confliction:
    //      Destination router's perspective: router would receive exactly two links:
    //          one from non-rolled source router and one from rolled source router
    //      Source's tranlation:
    //        1) if not rolled over (i.e., routerID < destination): connect to ingressPort 0
    //        2) if rolled over (i.e., routerID > destination): connect to ingressPort 1
    //

    // (1) Connect IngressRouter - First Level InternalRouter, Logic above doesn't change.
    // Values used to remove redundant for-loops:
    //      - networkLevel = 0
    //      - Only 1 segment of size TerminalNodesCount with routerOffset=0
    //      - First half is always not rolled over, Second half is always rolled over
    for (Integer routerID = 0; routerID < valueOf(TerminalNodesCount) / 2; routerID = routerID + 1) begin
        Integer destination = routerID + (valueOf(TerminalNodesCount) / 2);
    
        mkConnection(ingressRouters[routerID].egressPort[0].get, internalRouters[0][routerID].ingressPort[0].put);
        mkConnection(ingressRouters[routerID].egressPort[1].get, internalRouters[0][destination].ingressPort[0].put);
    end

    for (Integer routerID = valueOf(TerminalNodesCount) / 2; routerID < valueOf(TerminalNodesCount); routerID = routerID + 1) begin
        Integer destination = routerID - (valueOf(TerminalNodesCount) / 2);
    
        mkConnection(ingressRouters[routerID].egressPort[0].get, internalRouters[0][destination].ingressPort[1].put);
        mkConnection(ingressRouters[routerID].egressPort[1].get, internalRouters[0][routerID].ingressPort[1].put);
    end

    // (2) Connection among InternalRouters - using the algorithm above
    for (Integer networkLevel = 1; networkLevel < valueOf(NetworkLevelsCount); networkLevel = networkLevel + 1) begin
        Integer nodesInSegmentCount = valueOf(TerminalNodesCount) / (2 ** networkLevel);

        for (Integer segment = 0; segment < (2 ** networkLevel); segment = segment + 1) begin
            Integer segmentBase = segment * nodesInSegmentCount;

            for (Integer routerOffset = 0; routerOffset < nodesInSegmentCount; routerOffset = routerOffset + 1) begin
                Integer routerID = segmentBase + routerOffset;
                Integer destination = segmentBase + ((routerOffset + (nodesInSegmentCount / 2)) % nodesInSegmentCount);
                
                if (routerID < destination) begin
                    mkConnection(internalRouters[networkLevel - 1][routerID].egressPort[0].get, internalRouters[networkLevel][routerID].ingressPort[0].put);
                    mkConnection(internalRouters[networkLevel - 1][routerID].egressPort[1].get, internalRouters[networkLevel][destination].ingressPort[0].put);
                end else begin
                    mkConnection(internalRouters[networkLevel - 1][routerID].egressPort[0].get, internalRouters[networkLevel][destination].ingressPort[1].put);
                    mkConnection(internalRouters[networkLevel - 1][routerID].egressPort[1].get, internalRouters[networkLevel][routerID].ingressPort[1].put);
                end
            end
        end
    end

    
    // Interfaces
    Vector#(TerminalNodesCount, ButterflyNetworkIngressPort) ingressPortDefinition;
    for (Integer inPort = 0; inPort < valueOf(TerminalNodesCount); inPort = inPort + 1) begin
        ingressPortDefinition[inPort] = interface ButterflyNetworkIngressPort
            method Action put(Flit flit);
                ingressRouters[inPort].ingressPort.put(flit);
            endmethod
        endinterface;
    end

    Vector#(TerminalNodesCount, ButterflyNetworkEgressPort) egressPortDefinition;
    for (Integer outPort = 0; outPort < valueOf(TerminalNodesCount); outPort = outPort + 1) begin
        egressPortDefinition[outPort] = interface ButterflyNetworkEgressPort
            method ActionValue#(Flit) get;
                let receivedFlit <- internalRouters[valueOf(NetworkLevelsCount) - 1][outPort].egressPort[0].get;
                return receivedFlit;
            endmethod
        endinterface;
    end
    
    interface ingressPort = ingressPortDefinition;
    interface egressPort = egressPortDefinition;
endmodule
