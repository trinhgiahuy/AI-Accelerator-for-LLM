e): Adding Control Signals for Weight Stationary Dataflow

Modify the processing element (PE) array to support a weight stationary dataflow by adding appropriate control signals. This involves designing the data movement and control mechanisms to keep the weights stationary within the PEs while the inputs (activations) are streamed through


`weight_reg` holds the weight value loaded when `load_weight` is asserted

Array

Activations: Input activations are fed into the first row of PEs. Activations are shifted down through the PEs in the same column.

