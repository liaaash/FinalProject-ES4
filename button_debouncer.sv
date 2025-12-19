module button_debouncer (
    input  logic clk,
    input  logic button_raw,
    output logic button_pressed
);
    logic button_sync1, button_sync2, button_sync3;
    logic button_stable;
    logic button_stable_prev;
    logic [22:0] debounce_counter;
    logic [7:0] sample_history;
    
    // MOVED OUTSIDE - these need to be signals, not local variables
    logic [3:0] ones_count;
    logic button_filtered;
    
    parameter DEBOUNCE_TIME = 23'd4800000;  // ~100ms
    
    // Calculate ones_count combinationally
    always_comb begin
        ones_count = sample_history[0] + sample_history[1] + sample_history[2] + 
                     sample_history[3] + sample_history[4] + sample_history[5] + 
                     sample_history[6] + sample_history[7];
        button_filtered = (ones_count >= 4'd6);
    end
    
    always_ff @(posedge clk) begin
        // Three-stage synchronizer
        button_sync1 <= button_raw;
        button_sync2 <= button_sync1;
        button_sync3 <= button_sync2;
        
        // Sample history for majority voting
        if (debounce_counter[7:0] == 8'd0) begin
            sample_history <= {sample_history[6:0], button_sync3};
        end
        
        // Debounce the filtered signal
        if (button_filtered == button_stable) begin
            debounce_counter <= 0;
        end else begin
            if (debounce_counter < DEBOUNCE_TIME) begin
                debounce_counter <= debounce_counter + 1;
            end else begin
                button_stable <= button_filtered;
                debounce_counter <= 0;
            end
        end
        
        // Edge detection
        button_stable_prev <= button_stable;
        button_pressed <= button_stable && !button_stable_prev;
    end
endmodule