connect those processing elements in an array


```
[2024-10-04 01:59:35 UTC] iverilog '-Wall' '-g2012' design.sv testbench.sv  && unbuffer vvp a.out  
VCD info: dumpfile dump.vcd opened for output.
VCD warning: $dumpvars: Package ($unit) is not dumpable with VCD.
Accumulator values from all PEs:
PE[0]:                   32
PE[1]:                   21
PE[2]:                   12
PE[3]:                    5
testbench.sv:95: $finish called at 60000 (1ps)
Finding VCD file...
./dump.vcd
[2024-10-04 01:59:35 UTC] Opening EPWave...
Done
```
