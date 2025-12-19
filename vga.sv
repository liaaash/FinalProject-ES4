module vga #(
  parameter H_VISIBLE=640, H_FP=16, H_SYNC=96, H_BP=48,  H_TOTAL=640+16+96+48,
  parameter V_VISIBLE=480, V_FP=10, V_SYNC=2,  V_BP=33,  V_TOTAL=480+10+2+33
)(
  input  wire clk,
  output logic hsync, vsync,
  output logic [9:0] col, row,
  output logic visible
);
  int hcnt = 0;
  int vcnt = 0;

always_ff @(posedge clk) begin
    if (hcnt == H_TOTAL - 1) begin
        hcnt <= 0;
        if (vcnt == V_TOTAL - 1) 
            vcnt <= 0;
        else 
            vcnt <= vcnt + 1;
    end else begin 
        hcnt <= hcnt + 1;
    end
end

  assign visible = (hcnt<H_VISIBLE) && (vcnt<V_VISIBLE) ? 1'b1 : 1'b0;
  assign col     = hcnt;
  assign row     = vcnt;

  // active-low syncs
  assign hsync = (hcnt>=H_VISIBLE+H_FP) && (hcnt< H_VISIBLE+H_FP+H_SYNC) ? 1'b0 : 1'b1;
  assign vsync = (vcnt>=V_VISIBLE+V_FP) && (vcnt< V_VISIBLE+V_FP+V_SYNC) ? 1'b0 : 1'b1;
  
endmodule