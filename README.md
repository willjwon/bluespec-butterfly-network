<!-- MIT License

Copyright (c) 2020 Synergy Lab | Georgia Institute of Technology
Author: William Won (william.won@gatech.edu)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. -->

# bluespec-butterfly-network
Butterfly network implementation using Bluespec System Verilog

# Regular Butterfly Network (n-to-n butterfly)
## Instantiation
```bluespec
import RegularButterflyNetwork::*;

// RegularButterflyNetwork#(Terminal nodes count, terminal nodes address, payload datatype)
RegularButterflyNetwork#(8, Bit#(TLog#(8)), Bit#(32)) regularButterflyNetwork <- mkRegularButterflyNetwork;
    // 8-to-8 network, destination address Bit#(3), with payload type 32
```

## Usage
### Ingress Port
```bluespec
// network.ingressPort[source].put(destinationAddress, payload)
regularButterflyNetwork.ingressPort[3].put(3'd7, 11);  // sending data 11, from node 3 to node 7
```

### Egress Port
```bluespec
// network.egressPort[dest].get
let receivedPayload <- regularButterflyNetwork.egressPort[7].get;  // node 7 received payload
$display(receivedPayload);
```

## Compilation
### Non-pipelined
```bash
./RegularButterflyNetwork -v RegularButterflyNetwork non-pipelined
```

### Pipelined
```bash
./RegularButterflyNetwork -v RegularButterflyNetwork pipelined
```
