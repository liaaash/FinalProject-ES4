module square_wave (
    output logic sound,
    input logic [31:0] half_period,
    input logic clk
);

logic count, count2;

always @(posedge clk) begin
    count <= count + 1;
    if (count == 26'd0) begin
        count2 <= count2 + 1;
    end
end

// changing period changes notes 
// around 200000 is when it starts to fuck up
logic [31:0] counter = 0;

always @(posedge clk) begin
    if(counter >= half_period-1) begin
        counter <= 0;
        sound <= ~sound; // Toggle output
    end else begin
        counter <= counter + 1;
    end
end

endmodule