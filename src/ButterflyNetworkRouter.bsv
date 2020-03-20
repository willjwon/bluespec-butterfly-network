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


interface ButterflyNetworkRouterData#(type destinationAddressType, type payloadType);
    method Action put(destinationAddressType destinationAddress, payloadType payload);
    method ActionValue#(payloadType) getPayload;
    method ActionValue#(destinationAddressType) getDestinationAddress;
endinterface

interface ButterflyNetworkRouter#(type destinationAddressType, type payloadType);
    interface ButterflyNetworkRouterData#(destinationAddressType, payloadType) left;
    interface ButterflyNetworkRouterData#(destinationAddressType, payloadType) right;
endinterface


module mkButterflyNetworkRouter(ButterflyNetworkRouter#(destinationAddressType, payloadType))
provisos (Bits#(destinationAddressType, destinationAddressTypeWidth), Bitwise#(destinationAddressType), Bits#(payloadType, flitTypeWidth));
    /**
        Router for butterfly networt
        This would work as 2x2 crossbar
        
        This module assumes entering 2 inputs are already arbitrated (i.e., not requesting same output port)
    **/

    // Componenets
    // Input fifos
    Fifo#(1, payloadType) leftIngressPayload <- mkBypassFifo;
    Fifo#(1, destinationAddressType) leftIngressAddress <- mkBypassFifo;

    Fifo#(1, payloadType) rightIngressPayload <- mkBypassFifo;
    Fifo#(1, destinationAddressType) rightIngressAddress <- mkBypassFifo;

    // Output fifos
    Fifo#(1, payloadType) leftEgressPayload <- mkPipelineFifo;
    Fifo#(1, destinationAddressType) leftEgressAddress <- mkPipelineFifo;

    Fifo#(1, payloadType) rightEgressPayload <- mkPipelineFifo;
    Fifo#(1, destinationAddressType) rightEgressAddress <- mkPipelineFifo;

    
    // Rules
    rule forwardBoth if (leftIngressAddress.notEmpty && rightIngressAddress.notEmpty);
        // Assumption: already arbitrated
        if (msb(leftIngressAddress.first) == 0) begin
            // left to left
            leftEgressAddress.enq(leftIngressAddress.first << 1);
            leftEgressPayload.enq(leftIngressPayload.first);

            // right to right
            rightEgressAddress.enq(rightIngressAddress.first << 1);
            rightEgressPayload.enq(rightIngressPayload.first);
        end else begin
            // left to right
            rightEgressAddress.enq(leftIngressAddress.first << 1);
            rightEgressPayload.enq(leftIngressPayload.first);

            // right to left
            leftEgressAddress.enq(rightIngressAddress.first << 1);
            leftEgressPayload.enq(rightIngressPayload.first);
        end

        leftIngressAddress.deq;
        leftIngressPayload.deq;

        rightIngressAddress.deq;
        rightIngressPayload.deq;
    endrule

    rule forwardLeft if (leftIngressAddress.notEmpty && !rightIngressAddress.notEmpty);
            if (msb(leftIngressAddress.first) == 0) begin
            // left to left
            leftEgressAddress.enq(leftIngressAddress.first << 1);
            leftEgressPayload.enq(leftIngressPayload.first);
        end else begin
            // left to right
            rightEgressAddress.enq(leftIngressAddress.first << 1);
            rightEgressPayload.enq(leftIngressPayload.first);
        end

        leftIngressAddress.deq;
        leftIngressPayload.deq;
    endrule

    rule forwardRight if (!leftIngressAddress.notEmpty && rightIngressAddress.notEmpty);
        if (msb(rightIngressAddress.first) == 0) begin
            // right to left
            leftEgressAddress.enq(rightIngressAddress.first << 1);
            leftEgressPayload.enq(rightIngressPayload.first);    
        end else begin
            // right to right
            rightEgressAddress.enq(rightIngressAddress.first << 1);
            rightEgressPayload.enq(rightIngressPayload.first);
        end

        rightIngressAddress.deq;
        rightIngressPayload.deq;
    endrule


    // Interfaces
    interface left = interface ButterflyNetworkRouterData
        method Action put(destinationAddressType destinationAddress, payloadType payload);
            leftIngressAddress.enq(destinationAddress);
            leftIngressPayload.enq(payload);
        endmethod

        method ActionValue#(payloadType) getPayload;
            leftEgressPayload.deq;
            return leftEgressPayload.first;
        endmethod

        method ActionValue#(destinationAddressType) getDestinationAddress;
            leftEgressAddress.deq;
            return leftEgressAddress.first;
        endmethod
    endinterface;

    interface right = interface ButterflyNetworkRouterData
        method Action put(destinationAddressType destinationAddress, payloadType payload);
            rightIngressAddress.enq(destinationAddress);
            rightIngressPayload.enq(payload);
        endmethod

        method ActionValue#(payloadType) getPayload;
            rightEgressPayload.deq;
            return rightEgressPayload.first;
        endmethod

        method ActionValue#(destinationAddressType) getDestinationAddress;
            rightEgressAddress.deq;
            return rightEgressAddress.first;
        endmethod
    endinterface;
endmodule
