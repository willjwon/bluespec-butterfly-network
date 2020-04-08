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

## Setup
Change `./src/ButterflyNetworkType.bsv`.
```bluespec
// User-defined datatype settings
typedef 8 TerminalNodesCount;  // 8-to-8 Butterfly network
typedef Bit#(32) PayloadType;  // Actual payload is 8 bits
```

## Instantiation
```bluespec
import ButterflyNetworkType::*;
import ButterflyNetwork::*;

let butterflyNetwork <- mkButterflyNetwork;
```

## Usage
### Ingress Port
```bluespec
// Source Node 0 sending data 0 to Destination Node 1
butterflyNetwork.ingressPort[0].put(Flit{payload: 0, destinationAddress: 1});
```

### Egress Port
```bluespec
// Destination Node 1 receiving flit
let receivedFlit <- butterflyNetwork.egressPort[1].get;
$display(receivedFlit.payload);
```

## Compilation
### Non-pipelined
```bash
./ButterflyNetwork -v
# or
./ButterflyNetwork -v ButterflyNetwork nonpipelined
```

### Pipelined
```bash
./ButterflyNetwork -v ButterflyNetwork pipelined
```