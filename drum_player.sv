module drum_player #(
    parameter SAMPLE_LENGTH = 2415
)(
    input  logic clk,
    input  logic sample_tick,
    input  logic trigger,
    output logic [11:0] addr,
    output logic playing
);
    always_ff @(posedge clk) begin
        if (trigger && !playing) begin
            addr <= 0;
            playing <= 1;
        end else if (sample_tick && playing) begin
            if (addr == SAMPLE_LENGTH) begin
                addr <= 0;
                playing <= 0;
            end else begin
                addr <= addr + 1;
            end
        end
    end
endmodule