module pattern_gen(
  input  logic        clk,
  input  logic [9:0]  row,
  input  logic [9:0]  col,
  input  logic        visible,
  input  logic        hat_hit,
  input  logic        cymbal_hit,
  input  logic        tom_hit,
  //input  logic        timer_btn,
  input logic [5:0] seconds_i,
  output logic [5:0]  rgb
);

  // Drum positions and radii
  localparam HAT_X = 10'd200;
  localparam HAT_Y = 10'd200;
  localparam HAT_R = 10'd30;

  localparam CYMBAL_X = 10'd440;
  localparam CYMBAL_Y = 10'd180;
  localparam CYMBAL_R = 10'd40;

  localparam TOM_X = 10'd320;
  localparam TOM_Y = 10'd320;
  localparam TOM_R = 10'd50;

  // Label placement (3 letters, 5x7 glyphs with 1px spacing => 18x7 block)
  localparam int LABEL_W = 18;
  localparam int LABEL_H = 7;
  localparam int HAT_LABEL_X = HAT_X - (LABEL_W/2);
  localparam int HAT_LABEL_Y = HAT_Y - HAT_R - 18;
  localparam int CYM_LABEL_X = CYMBAL_X - (LABEL_W/2);
  localparam int CYM_LABEL_Y = CYMBAL_Y - CYMBAL_R - 18;
  localparam int TOM_LABEL_X = TOM_X - (LABEL_W/2);
  localparam int TOM_LABEL_Y = TOM_Y - TOM_R - 18;

  // --- Drum Flash Timers and Logic (ADD THESE LINES) ---
  logic [11:0] hat_flash_count;
  logic [11:0] cymbal_flash_count;
  logic [11:0] tom_flash_count;

  // Define the fade duration (in clock cycles @ 25MHz)
  localparam int HAT_FADE_MAX = 12'd1000; // Fast (40 µs)
  localparam int CYM_FADE_MAX = 17'd100000; // Slower (4 ms)
  localparam int TOM_FADE_MAX = 15'd25000;
  
  // Flash state (wire is 1 when the counter is greater than 0)
  wire hat_flash = (hat_flash_count != 0);
  wire cymbal_flash = (cymbal_flash_count != 0);
  wire tom_flash = (tom_flash_count != 0);

  // Simple circle check for drum shapes
  function logic in_circle(
    input [9:0] x,
    input [9:0] y,
    input int   cx,
    input int   cy,
    input int   r
  );
    in_circle = ((x - cx)*(x - cx) + (y - cy)*(y - cy)) <= (r*r);
  endfunction

  // 5x7 uppercase glyphs for quick labels
  function logic glyph_pixel(
    input byte      c,
    input [2:0]     px,
    input [2:0]     py
  );
    logic [4:0] row;
    begin
      case (c)
        "A": case (py)  // 0..6
               3'd0: row = 5'b01110;
               3'd1: row = 5'b10001;
               3'd2: row = 5'b10001;
               3'd3: row = 5'b11111;
               3'd4: row = 5'b10001;
               3'd5: row = 5'b10001;
               3'd6: row = 5'b10001;
               default: row = 5'b00000;
             endcase
        "B": case (py)
               3'd0: row = 5'b11110;
               3'd1: row = 5'b10001;
               3'd2: row = 5'b10001;
               3'd3: row = 5'b11110;
               3'd4: row = 5'b10001;
               3'd5: row = 5'b10001;
               3'd6: row = 5'b11110;
               default: row = 5'b00000;
             endcase
        "C": case (py)
               3'd0: row = 5'b01110;
               3'd1: row = 5'b10001;
               3'd2: row = 5'b10000;
               3'd3: row = 5'b10000;
               3'd4: row = 5'b10000;
               3'd5: row = 5'b10001;
               3'd6: row = 5'b01110;
               default: row = 5'b00000;
             endcase
        "H": case (py)
               3'd0: row = 5'b10001;
               3'd1: row = 5'b10001;
               3'd2: row = 5'b10001;
               3'd3: row = 5'b11111;
               3'd4: row = 5'b10001;
               3'd5: row = 5'b10001;
               3'd6: row = 5'b10001;
               default: row = 5'b00000;
             endcase
        "D": case (py)
               3'd0: row = 5'b11100;
               3'd1: row = 5'b10010;
               3'd2: row = 5'b10001;
               3'd3: row = 5'b10001;
               3'd4: row = 5'b10001;
               3'd5: row = 5'b10010;
               3'd6: row = 5'b11100;
               default: row = 5'b00000;
             endcase
        "E": case (py)
               3'd0: row = 5'b11111;
               3'd1: row = 5'b10000;
               3'd2: row = 5'b10000;
               3'd3: row = 5'b11110;
               3'd4: row = 5'b10000;
               3'd5: row = 5'b10000;
               3'd6: row = 5'b11111;
               default: row = 5'b00000;
             endcase
        "F": case (py)
               3'd0: row = 5'b11111;
               3'd1: row = 5'b10000;
               3'd2: row = 5'b10000;
               3'd3: row = 5'b11110;
               3'd4: row = 5'b10000;
               3'd5: row = 5'b10000;
               3'd6: row = 5'b10000;
               default: row = 5'b00000;
             endcase
        "0": case (py)
               3'd0: row = 5'b01110;
               3'd1: row = 5'b10001;
               3'd2: row = 5'b10011;
               3'd3: row = 5'b10101;
               3'd4: row = 5'b11001;
               3'd5: row = 5'b10001;
               3'd6: row = 5'b01110;
               default: row = 5'b00000;
             endcase
        "1": case (py)
               3'd0: row = 5'b00100;
               3'd1: row = 5'b01100;
               3'd2: row = 5'b00100;
               3'd3: row = 5'b00100;
               3'd4: row = 5'b00100;
               3'd5: row = 5'b00100;
               3'd6: row = 5'b01110;
               default: row = 5'b00000;
             endcase
        "2": case (py)
               3'd0: row = 5'b01110;
               3'd1: row = 5'b10001;
               3'd2: row = 5'b00001;
               3'd3: row = 5'b00010;
               3'd4: row = 5'b00100;
               3'd5: row = 5'b01000;
               3'd6: row = 5'b11111;
               default: row = 5'b00000;
             endcase
        "3": case (py)
               3'd0: row = 5'b11110;
               3'd1: row = 5'b00001;
               3'd2: row = 5'b00001;
               3'd3: row = 5'b01110;
               3'd4: row = 5'b00001;
               3'd5: row = 5'b00001;
               3'd6: row = 5'b11110;
               default: row = 5'b00000;
             endcase
        "4": case (py)
               3'd0: row = 5'b00010;
               3'd1: row = 5'b00110;
               3'd2: row = 5'b01010;
               3'd3: row = 5'b10010;
               3'd4: row = 5'b11111;
               3'd5: row = 5'b00010;
               3'd6: row = 5'b00010;
               default: row = 5'b00000;
             endcase
        "5": case (py)
               3'd0: row = 5'b11111;
               3'd1: row = 5'b10000;
               3'd2: row = 5'b10000;
               3'd3: row = 5'b11110;
               3'd4: row = 5'b00001;
               3'd5: row = 5'b00001;
               3'd6: row = 5'b11110;
               default: row = 5'b00000;
             endcase
        "6": case (py)
               3'd0: row = 5'b01110;
               3'd1: row = 5'b10000;
               3'd2: row = 5'b10000;
               3'd3: row = 5'b11110;
               3'd4: row = 5'b10001;
               3'd5: row = 5'b10001;
               3'd6: row = 5'b01110;
               default: row = 5'b00000;
             endcase
        "7": case (py)
               3'd0: row = 5'b11111;
               3'd1: row = 5'b00001;
               3'd2: row = 5'b00010;
               3'd3: row = 5'b00100;
               3'd4: row = 5'b01000;
               3'd5: row = 5'b01000;
               3'd6: row = 5'b01000;
               default: row = 5'b00000;
             endcase
        "8": case (py)
               3'd0: row = 5'b01110;
               3'd1: row = 5'b10001;
               3'd2: row = 5'b10001;
               3'd3: row = 5'b01110;
               3'd4: row = 5'b10001;
               3'd5: row = 5'b10001;
               3'd6: row = 5'b01110;
               default: row = 5'b00000;
             endcase
        "9": case (py)
               3'd0: row = 5'b01110;
               3'd1: row = 5'b10001;
               3'd2: row = 5'b10001;
               3'd3: row = 5'b01111;
               3'd4: row = 5'b00001;
               3'd5: row = 5'b00001;
               3'd6: row = 5'b01110;
               default: row = 5'b00000;
             endcase
        "M": case (py)
               3'd0: row = 5'b10001;
               3'd1: row = 5'b11011;
               3'd2: row = 5'b10101;
               3'd3: row = 5'b10001;
               3'd4: row = 5'b10001;
               3'd5: row = 5'b10001;
               3'd6: row = 5'b10001;
               default: row = 5'b00000;
             endcase
        "O": case (py)
               3'd0: row = 5'b01110;
               3'd1: row = 5'b10001;
               3'd2: row = 5'b10001;
               3'd3: row = 5'b10001;
               3'd4: row = 5'b10001;
               3'd5: row = 5'b10001;
               3'd6: row = 5'b01110;
               default: row = 5'b00000;
             endcase
        "T": case (py)
               3'd0: row = 5'b11111;
               3'd1: row = 5'b00100;
               3'd2: row = 5'b00100;
               3'd3: row = 5'b00100;
               3'd4: row = 5'b00100;
               3'd5: row = 5'b00100;
               3'd6: row = 5'b00100;
               default: row = 5'b00000;
             endcase
        "Y": case (py)
               3'd0: row = 5'b10001;
               3'd1: row = 5'b10001;
               3'd2: row = 5'b01010;
               3'd3: row = 5'b00100;
               3'd4: row = 5'b00100;
               3'd5: row = 5'b00100;
               3'd6: row = 5'b00100;
               default: row = 5'b00000;
             endcase
        default: row = 5'b00000;
      endcase

      // Left-to-right within the 5 columns
      if (px < 5 && py < 7) glyph_pixel = row[4 - px];
      else                  glyph_pixel = 1'b0;
    end
  endfunction

  // Helper to draw a 3-letter word using the 5x7 glyphs
  function logic label_pixel(
    input [9:0] x,
    input [9:0] y,
    input int   start_x,
    input int   start_y,
    input byte  c0,
    input byte  c1,
    input byte  c2
  );
    int        idx;
    byte       ch;
    logic [2:0] px, py;
    begin
      label_pixel = 1'b0;
      if (x >= start_x && x < start_x + LABEL_W &&
          y >= start_y && y < start_y + LABEL_H) begin
        idx = (x - start_x) / 6;
        px  = (x - start_x) % 6;
        py  = (y - start_y);
        if (px < 5) begin
          case (idx)
            0: ch = c0;
            1: ch = c1;
            default: ch = c2;
          endcase
          label_pixel = glyph_pixel(ch, px, py);
        end
      end
    end
  endfunction

  function logic timer_pixel(
    input [9:0] x,
    input [9:0] y,
    input int   start_x,
    input int   start_y,
    input [15:0] val
  );
    int        idx;
    byte       ch;
    int        tmp;
    int        ones, tens, hundreds, thousands;
    logic [2:0] px, py;
    begin
      timer_pixel = 1'b0;

      tmp       = val;
      ones      = tmp % 10;
      tmp       = tmp / 10;
      tens      = tmp % 10;
      tmp       = tmp / 10;
      hundreds  = tmp % 10;
      tmp       = tmp / 10;
      thousands = tmp % 10;

      if (x >= start_x && x < start_x + 30 &&
          y >= start_y && y < start_y + LABEL_H) begin
        idx = (x - start_x) / 6;    // 5 chars * 6px spacing
        px  = (x - start_x) % 6;
        py  = (y - start_y);
        if (px < 5) begin
          case (idx)
            0: ch = "T";
            1: ch = (thousands == 0) ? 8'd0 : byte'("0" + thousands);
            2: ch = ((thousands == 0) && (hundreds == 0)) ? 8'd0 : byte'("0" + hundreds);
            3: ch = ((thousands == 0) && (hundreds == 0) && (tens == 0)) ? 8'd0 : byte'("0" + tens);
            default: ch = byte'("0" + ones);
          endcase
          if (ch != 8'd0) timer_pixel = glyph_pixel(ch, px, py);
        end
      end
    end
  endfunction

  always_ff @(posedge clk) begin
    if (hat_hit)
      hat_flash_count <= HAT_FADE_MAX;
    else if (hat_flash_count != 0)
      hat_flash_count <= hat_flash_count - 1;
    // Cymbal
    if (cymbal_hit)
      cymbal_flash_count <= CYM_FADE_MAX;
    else if (cymbal_flash_count != 0)
      cymbal_flash_count <= cymbal_flash_count - 1;
    // --- Tom Flash ---
    if (tom_hit)
      tom_flash_count <= TOM_FADE_MAX;
    else if (tom_flash_count != 0)
      tom_flash_count <= tom_flash_count - 1;
  end

  always_comb begin
    // Dark background by default
    rgb = 6'b000000;

    if (visible) begin
      rgb = 6'b111111; // white background

      // Hi-hat: yellow-green, hops when flashing
      if (in_circle(col, row, HAT_X, HAT_Y - (hat_flash ? 4 : 0), HAT_R)) begin
        rgb = hat_flash ? 6'b110110 : 6'b010110;

      // Ride/Crash cymbal: bright yellow, rises on hit
      end else if (in_circle(col, row, CYMBAL_X, CYMBAL_Y - (cymbal_flash ? 3 : 0), CYMBAL_R)) begin
        rgb = cymbal_flash ? 6'b111110 : 6'b101100;

      // Tom: cyan/blue, small bump on hit
      end else if (in_circle(col, row, TOM_X, TOM_Y - (tom_flash ? 3 : 0), TOM_R)) begin
        rgb = tom_flash ? 6'b011111 : 6'b001111;
      end

      if (label_pixel(col, row, HAT_LABEL_X, HAT_LABEL_Y, "H", "A", "T")) begin
        rgb = 6'b000000;
      end else if (label_pixel(col, row, CYM_LABEL_X, CYM_LABEL_Y, "C", "Y", "M")) begin
        rgb = 6'b000000;
      end else if (label_pixel(col, row, TOM_LABEL_X, TOM_LABEL_Y, "T", "O", "M")) begin
        rgb = 6'b000000;
      // Show timer value even when paused
      end else if (timer_pixel(col, row, 10, 10, seconds_i)) begin
        rgb = 6'b000000;
      end
    end
  end
endmodule