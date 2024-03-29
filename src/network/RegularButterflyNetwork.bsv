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
import Connectable::*;
import IngressSwitch::*;
import InternalSwitch::*;
import EgressSwitch::*;


interface RegularButterflyNetworkIngressPort#(type addressType, type payloadType);
    method Action put(addressType destinationAddress, payloadType payload);
endinterface

interface RegularButterflyNetworkEgressPort#(type payloadType);
    method ActionValue#(payloadType) get;
endinterface

interface RegularButterflyNetwork#(numeric type terminalNodesCount, type addressType, type payloadType);
    interface Vector#(terminalNodesCount, RegularButterflyNetworkIngressPort#(addressType, payloadType)) ingressPort;
    interface Vector#(terminalNodesCount, RegularButterflyNetworkEgressPort#(payloadType)) egressPort;
endinterface


module mkRegularButterflyNetwork(RegularButterflyNetwork#(terminalNodesCount, addressType, payloadType)) provisos (
    Bits#(addressType, addressTypeBitLength),
    Bitwise#(addressType),
    Log#(terminalNodesCount, addressTypeBitLength),
    Bits#(payloadType, payloadTypeBitLength),
    Alias#(Tuple2#(addressType, payloadType), flitType),
    NumAlias#(TLog#(terminalNodesCount), networkLevelsCount)
);
    /**
        Regular butterfly topology
    **/

    // Components
    Vector#(terminalNodesCount, IngressSwitch#(addressType, payloadType)) ingressSwitches <- replicateM(mkIngressSwitch);
    Vector#(TSub#(networkLevelsCount, 1), Vector#(terminalNodesCount, InternalSwitch#(addressType, payloadType))) internalSwitches <- replicateM(replicateM(mkInternalSwitch));
    Vector#(terminalNodesCount, EgressSwitch#(addressType, payloadType)) egressSwitches <- replicateM(mkEgressSwitch);


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

    // (1) Connect ingressSwitches - First Level InternalRouter, Logic above doesn't change.
    // Values used to remove redundant for-loops:
    //      - networkLevel = 0
    //      - Only 1 segment of size terminalNodesCount with routerOffset=0
    //      - First half is always not rolled over, Second half is always rolled over
    for (Integer routerID = 0; routerID < valueOf(terminalNodesCount) / 2; routerID = routerID + 1) begin
        Integer destination = routerID + (valueOf(terminalNodesCount) / 2);
    
        mkConnection(ingressSwitches[routerID].egressPort[0].get, internalSwitches[0][routerID].ingressPort[0].put);
        mkConnection(ingressSwitches[routerID].egressPort[1].get, internalSwitches[0][destination].ingressPort[0].put);
    end

    for (Integer routerID = valueOf(terminalNodesCount) / 2; routerID < valueOf(terminalNodesCount); routerID = routerID + 1) begin
        Integer destination = routerID - (valueOf(terminalNodesCount) / 2);
    
        mkConnection(ingressSwitches[routerID].egressPort[0].get, internalSwitches[0][destination].ingressPort[1].put);
        mkConnection(ingressSwitches[routerID].egressPort[1].get, internalSwitches[0][routerID].ingressPort[1].put);
    end

    // (2) Connection among InternalRouters - using the algorithm above
    for (Integer networkLevel = 1; networkLevel < valueOf(networkLevelsCount) - 1; networkLevel = networkLevel + 1) begin
        Integer nodesInSegmentCount = valueOf(terminalNodesCount) / (2 ** networkLevel);

        for (Integer segment = 0; segment < (2 ** networkLevel); segment = segment + 1) begin
            Integer segmentBase = segment * nodesInSegmentCount;

            for (Integer routerOffset = 0; routerOffset < nodesInSegmentCount; routerOffset = routerOffset + 1) begin
                Integer routerID = segmentBase + routerOffset;
                Integer destination = segmentBase + ((routerOffset + (nodesInSegmentCount / 2)) % nodesInSegmentCount);
                
                if (routerID < destination) begin
                    mkConnection(internalSwitches[networkLevel - 1][routerID].egressPort[0].get, internalSwitches[networkLevel][routerID].ingressPort[0].put);
                    mkConnection(internalSwitches[networkLevel - 1][routerID].egressPort[1].get, internalSwitches[networkLevel][destination].ingressPort[0].put);
                end else begin
                    mkConnection(internalSwitches[networkLevel - 1][routerID].egressPort[0].get, internalSwitches[networkLevel][destination].ingressPort[1].put);
                    mkConnection(internalSwitches[networkLevel - 1][routerID].egressPort[1].get, internalSwitches[networkLevel][routerID].ingressPort[1].put);
                end
            end
        end
    end

    // (3) Connect Last level InternalRouter - EgressRouter, Logic above doesn't change.
    // Values used to remove redundant for-loops:
    //      - networkLevel = valueOf(networkLevelsCount) - 1
    //      - router 0, 2, 4, ... wouldn't be rolled over
    //      - router 1, 3, 5, ..., would be rolled over
    Integer lastLevel = valueOf(networkLevelsCount) - 2;
    for (Integer routerID = 0; routerID < valueOf(terminalNodesCount); routerID = routerID + 2) begin
        // routers not rolled over
        // destination would be (routerID, routerID + 1)
        mkConnection(internalSwitches[lastLevel][routerID].egressPort[0].get, egressSwitches[routerID].ingressPort[0].put);
        mkConnection(internalSwitches[lastLevel][routerID].egressPort[1].get, egressSwitches[routerID + 1].ingressPort[0].put);
    end

    for (Integer routerID = 1; routerID < valueOf(terminalNodesCount); routerID = routerID + 2) begin
        // routers rolled over
        // destination would be (routerID - 1, routerID)
        mkConnection(internalSwitches[lastLevel][routerID].egressPort[0].get, egressSwitches[routerID - 1].ingressPort[1].put);
        mkConnection(internalSwitches[lastLevel][routerID].egressPort[1].get, egressSwitches[routerID].ingressPort[1].put);
    end

    
    // Interfaces
    Vector#(terminalNodesCount, RegularButterflyNetworkIngressPort#(addressType, payloadType)) ingressPortDefinition;
    for (Integer inPort = 0; inPort < valueOf(terminalNodesCount); inPort = inPort + 1) begin
        ingressPortDefinition[inPort] = interface RegularButterflyNetworkIngressPort#(addressType, payloadType)
            method Action put(addressType destinationAddress, payloadType payload);
                ingressSwitches[inPort].ingressPort.put(destinationAddress, payload);
            endmethod
        endinterface;
    end

    Vector#(terminalNodesCount, RegularButterflyNetworkEgressPort#(payloadType)) egressPortDefinition;
    for (Integer outPort = 0; outPort < valueOf(terminalNodesCount); outPort = outPort + 1) begin
        egressPortDefinition[outPort] = interface RegularButterflyNetworkEgressPort#(payloadType)
            method ActionValue#(payloadType) get;
                let receivedPayload <- egressSwitches[outPort].egressPort.get;
                return receivedPayload;
            endmethod
        endinterface;
    end
    
    interface ingressPort = ingressPortDefinition;
    interface egressPort = egressPortDefinition;
endmodule
