module vga_top(
  input  wire ref_clk_i,       
  input  wire hat_hit_i,
  input  wire cymbal_hit_i,
  input  wire tom_hit_i,
  input  wire timer_btn_i,
  output wire hsync_o,
  output wire vsync_o,
  output wire [5:0] rgb_o,
  output wire pll
);

    wire pllclk;

    mypll mypll_inst(
        .ref_clk_i(ref_clk_i),
        .rst_n_i(1'b1),
        .outglobal_o(pllclk),
    );
  
    assign pll = pllclk;
    // VGA timing
    wire [9:0] col, row;
    wire       vis;
    vga u_vga(
        .clk(pllclk),
        .hsync(hsync_o),
        .vsync(vsync_o),
        .col(col),
        .row(row),
        .visible(vis)
    );

    wire[5:0] timer_seconds_6b;
    wire timer_enable = 1'b1;
    wire timer_reset = ~timer_btn_i;
    // Timer
    timer u_timer(
      .clk(pllclk),
      .reset(timer_reset),
      .enable(timer_enable),
      .seconds(timer_seconds_6b)
    );

    // Pattern
    pattern_gen u_pat(
        .clk(pllclk),
        .row(row), 
        .col(col), 
        .visible(vis),
        .hat_hit(hat_hit_i),
        .cymbal_hit(cymbal_hit_i),
        .tom_hit(tom_hit_i),
        .seconds_i(timer_seconds_6b),
        .rgb(rgb_o)
    );
endmodule