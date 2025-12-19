module audio_rom_snare (
    input  logic clk,
    input  logic [11:0] addr,
    output logic [7:0] data_out
);

    logic [7:0] mem [0:728];

    initial begin
        $readmemh("snare8.hex", mem);
    end

    always_ff @(posedge clk) begin
        data_out <= mem[addr];
    end

endmodule