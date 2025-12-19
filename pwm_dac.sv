module pwm_dac (
    input  logic clk,
    input  logic [7:0] sample,  // 8-bit
    output logic pwm_out
);

    logic [7:0] counter;

    always_ff @(posedge clk) begin
        counter <= counter + 1;
        pwm_out <= (counter < sample);
    end

endmodule
