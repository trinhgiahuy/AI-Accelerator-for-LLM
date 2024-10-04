add on mixed precision support to that

```
[2024-10-04 02:19:35 UTC] iverilog '-Wall' '-g2012' design.sv testbench.sv  && unbuffer vvp a.out  
VCD info: dumpfile dump.vcd opened for output.
VCD warning: $dumpvars: Package ($unit) is not dumpable with VCD.
Final Accumulator Value:                   98
testbench.sv:66: $finish called at 100000 (1ps)
Finding VCD file...
./dump.vcd
[2024-10-04 02:19:35 UTC] Opening EPWave...
Done
```
