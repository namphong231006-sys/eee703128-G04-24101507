`ifdef G04_SVA

// The following properties are scaffold-level and assume the unsigned interface.
// Freeze exact cycle semantics from the official HTML before enabling them.

assert_no_wrap_after_saturation:
    assert property (@(posedge clk)
        (dut.acc_q == 16'hFFFF && valid_in) |=> dut.acc_q == 16'hFFFF);

`endif
