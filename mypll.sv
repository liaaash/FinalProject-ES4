/**
 * PLL configuration
 *
 * This Verilog module was generated automatically
 * using the icepll tool from the IceStorm project.
 * Use at your own risk.
 *
 * Given input frequency:        12.000 MHz
 * Requested output frequency:   25.175 MHz
 * Achieved output frequency:    25.125 MHz
 */

module mypll(
	input  ref_clk_i,
	input  rst_n_i,
	output outcore_o,
	output outglobal_o
);

	wire lock;

	SB_PLL40_CORE #(
			.FEEDBACK_PATH("SIMPLE"),
			.DIVR(4'd0),		// DIVR =  0
			.DIVF(7'd66),	// DIVF = 66
			.DIVQ(3'd5),		// DIVQ =  5
			.FILTER_RANGE(3'b001)	// FILTER_RANGE = 1\
	)   pll_inst (
			.LOCK(lock),
			.RESETB(rst_n_i),
			.BYPASS(1'b0),
			.REFERENCECLK(ref_clk_i),
			.PLLOUTCORE(outcore_o),
			.PLLOUTGLOBAL(outglobal_o)
		);

endmodule