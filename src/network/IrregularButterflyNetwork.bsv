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


import Vector::*;
import Connectable::*;
import IngressSwitch::*;
import InternalSwitch::*;
import EgressSwitch::*;
import EgressTreeSwitch::*;


interface IrregularButterflyNetworkIngressPort#(type addressType, type payloadType);
    method Action put(addressType destinationAddress, payloadType payload);
endinterface

interface IrregularButterflyNetworkEgressPort#(type payloadType);
    method ActionValue#(payloadType) get;
endinterface


interface IrregularButterflyNetwork#(numeric type ingressPortsCount, numeric type egressPortsCount, type addressType, type payloadType);
    interface Vector#(ingressPortsCount, IrregularButterflyNetworkIngressPort#(addressType, payloadType)) ingressPort;
    interface Vector#(egressPortsCount, IrregularButterflyNetworkEgressPort#(payloadType)) egressPort;
endinterface

// Mathematical notation



module mkIrregularButterflyNetwork(IrregularButterflyNetwork#(ingressPortsCount, egressPortsCount, addressType, payloadType)) provisos (
    Bits#(addressType, addressTypeBitLength),
    Bitwise#(addressType),
    Bits#(payloadType, payloadTypeBitLength),
    Log#(egressPortsCount, addressTypeBitLength),
    NumAlias#(TDiv#(ingressPortsCount, egressPortsCount), srcToDestRatio),
    NumAlias#(TSub#(TLog#(srcToDestRatio), 1), internalLevelsCount),
    NumAlias#(TSub#(srcToDestRatio, 1), treeNodesCount)
);
    /**
    * (ingressPortsCount)-to-(egressPortsCount) irregular butterfly network
    */

    // Mathematical notation
    Integer lastLevel = valueOf(internalLevelsCount) - 1;
    Integer leavesCount = valueOf(srcToDestRatio) / 2;
    Integer leafStartIndex = leavesCount - 1;
    

    // Submodule
    Vector#(ingressPortsCount, IngressSwitch#(addressType, payloadType)) ingressSwitches <- replicateM(mkIngressSwitch);
    Vector#(internalLevelsCount, Vector#(ingressPortsCount, InternalSwitch#(addressType, payloadType)))
        internalSwitches <- replicateM(replicateM(mkInternalSwitch));
    Vector#(ingressPortsCount, EgressSwitch#(addressType, payloadType)) egressSwitches <- replicateM(mkEgressSwitch);
    Vector#(egressPortsCount, Vector#(treeNodesCount, EgressTreeSwitch#(payloadType)))
        egressTreeSwitches <- replicateM(replicateM(mkEgressTreeSwitch));


    // Connection: ingressSwitches - internalSwitches[0]
    Integer firstSectionLength = valueOf(TDiv#(ingressPortsCount, 2));
    for (Integer i = 0; i < firstSectionLength; i = i + 1) begin
        mkConnection(ingressSwitches[i].egressPort[0].get, internalSwitches[0][i].ingressPort[0].put);
        mkConnection(ingressSwitches[i].egressPort[1].get, internalSwitches[0][i + firstSectionLength].ingressPort[0].put);
    end

    for (Integer i = firstSectionLength; i < valueOf(ingressPortsCount); i = i + 1) begin
        mkConnection(ingressSwitches[i].egressPort[0].get, internalSwitches[0][i - firstSectionLength].ingressPort[1].put);
        mkConnection(ingressSwitches[i].egressPort[1].get, internalSwitches[0][i].ingressPort[1].put);
    end

    // Connection: internalSwitches
    for (Integer level = 0; level < lastLevel; level = level + 1) begin
        Integer sectionsCount = 2 ** (2 + level);
        Integer sectionLength = valueOf(ingressPortsCount) / sectionsCount;
        for (Integer section = 0; section < sectionsCount; section = section + 2) begin
           // even sections
           Integer startNodeIndex = section * sectionLength;
           for (Integer i = startNodeIndex; i < (startNodeIndex + sectionLength); i = i + 1) begin
               mkConnection(internalSwitches[level][i].egressPort[0].get, internalSwitches[level + 1][i].ingressPort[0].put);
               mkConnection(internalSwitches[level][i].egressPort[1].get, internalSwitches[level + 1][i + sectionLength].ingressPort[0].put);
           end
        end

        for (Integer section = 1; section < sectionsCount; section = section + 2) begin
            // odd sections
            Integer startNodeIndex = section * sectionLength;
            for (Integer i = startNodeIndex; i < (startNodeIndex + sectionLength); i = i + 1) begin
               mkConnection(internalSwitches[level][i].egressPort[0].get, internalSwitches[level + 1][i - sectionLength].ingressPort[1].put);
               mkConnection(internalSwitches[level][i].egressPort[1].get, internalSwitches[level + 1][i].ingressPort[1].put);
           end
        end
    end

    // Connection: internalSwitches lastLevel - egerssSwitches
    Integer lastSectionLength = valueOf(srcToDestRatio);
    Integer lastSectionsCount = valueOf(ingressPortsCount) / lastSectionLength;
    for (Integer section = 0; section < lastSectionsCount; section = section + 2) begin
        // even sections
        Integer startNodeIndex = section * lastSectionLength;
        for (Integer i = startNodeIndex; i < (startNodeIndex + lastSectionLength); i = i + 1) begin
            mkConnection(internalSwitches[lastLevel][i].egressPort[0].get, egressSwitches[i].ingressPort[0].put);
            mkConnection(internalSwitches[lastLevel][i].egressPort[1].get, egressSwitches[i + lastSectionLength].ingressPort[0].put);
        end
    end

    for (Integer section = 1; section < lastSectionsCount; section = section + 2) begin
        // odd sections
        Integer startNodeIndex = section * lastSectionLength;
        for (Integer i = startNodeIndex; i < (startNodeIndex + lastSectionLength); i = i + 1) begin
            mkConnection(internalSwitches[lastLevel][i].egressPort[0].get, egressSwitches[i - lastSectionLength].ingressPort[1].put);
            mkConnection(internalSwitches[lastLevel][i].egressPort[1].get, egressSwitches[i].ingressPort[1].put);
        end
    end

    // Connection: egressSwitches - egressTreeSwitches leaves
    for (Integer section = 0; section < valueOf(egressPortsCount); section = section + 1) begin
        for (Integer nodeOffset = 0; nodeOffset < valueOf(srcToDestRatio); nodeOffset = nodeOffset + 2) begin
            // even nodes
            Integer nodeIndex = (section * valueOf(srcToDestRatio)) + nodeOffset;
            Integer leafIndex = leafStartIndex + (nodeOffset / 2);
            mkConnection(egressSwitches[nodeIndex].egressPort.get, egressTreeSwitches[section][leafIndex].ingressPort[0].put);
        end
    end

    for (Integer section = 0; section < valueOf(egressPortsCount); section = section + 1) begin
        for (Integer nodeOffset = 1; nodeOffset < valueOf(srcToDestRatio); nodeOffset = nodeOffset + 2) begin
            // odd nodes
            Integer nodeIndex = (section * valueOf(srcToDestRatio)) + nodeOffset;
            Integer leafIndex = leafStartIndex + (nodeOffset / 2);
            mkConnection(egressSwitches[nodeIndex].egressPort.get, egressTreeSwitches[section][leafIndex].ingressPort[1].put);
        end
    end
    
    // Connection: egressTreeSwitches
    for (Integer i = 0; i < leafStartIndex; i = i + 1) begin
        for (Integer section = 0; section < valueOf(egressPortsCount); section = section + 1) begin
            Integer leftChildIndex = (i * 2) + 1;
            Integer rightChildIndex = leftChildIndex + 1;
            
            mkConnection(egressTreeSwitches[section][leftChildIndex].egressPort.get, egressTreeSwitches[section][i].ingressPort[0].put);
            mkConnection(egressTreeSwitches[section][rightChildIndex].egressPort.get, egressTreeSwitches[section][i].ingressPort[1].put);
        end
    end


    // Interface
    Vector#(ingressPortsCount, IrregularButterflyNetworkIngressPort#(addressType, payloadType)) ingressPortDefinition = newVector;
    for (Integer i = 0; i < valueOf(ingressPortsCount); i = i + 1) begin
        ingressPortDefinition[i] = interface IrregularButterflyNetworkIngressPort#(addressType, payloadType)
            method Action put(addressType destinationAddress, payloadType payload);
                ingressSwitches[i].ingressPort.put(destinationAddress, payload);
            endmethod
        endinterface;
    end

    Vector#(egressPortsCount, IrregularButterflyNetworkEgressPort#(payloadType)) egressPortDefinition = newVector;
    for (Integer i = 0; i < valueOf(egressPortsCount); i = i + 1) begin
        egressPortDefinition[i] = interface IrregularButterflyNetworkEgressPort#(payloadType)
            method ActionValue#(payloadType) get;
                let value <- egressTreeSwitches[i][0].egressPort.get;
                return value;
            endmethod
        endinterface;
    end

    interface ingressPort = ingressPortDefinition;
    interface egressPort = egressPortDefinition;
endmodule
