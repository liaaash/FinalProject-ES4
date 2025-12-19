module audio_rom_hihat (
    input  logic clk,
    input  logic [11:0] addr,
    output logic [7:0] data_out
);

    logic [7:0] mem [0:485];

    initial begin
        $readmemh("hihat8.hex", mem);
    end

    always_ff @(posedge clk) begin
        data_out <= mem[addr];
    end

endmodule