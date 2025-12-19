module memory (
    input  logic clk,
    input  logic rst,
    input  logic rec_en,
    input  logic play_en,
    input  logic sample_tick,
    input  logic cymbal_pressed,
    input  logic snare_pressed,
    input  logic hihat_pressed,
    input  logic tom_pressed,
    input  logic kick_pressed,
    output logic play_cymbal,
    output logic play_hihat,
    output logic play_tom,
    output logic play_snare,
    output logic play_kick,
    output logic rec_done
);
    
    parameter MAX_EVENTS = 128;
    parameter EVENT_WIDTH = 20;           
    parameter TIMESTAMP_WIDTH = 17;
    
    logic [EVENT_WIDTH-1:0] event_memory [0:MAX_EVENTS-1];
    logic [6:0] event_count;
    logic [6:0] write_ptr;
    logic [6:0] play_ptr;
    
    logic [TIMESTAMP_WIDTH-1:0] rec_timestamp;
    logic [TIMESTAMP_WIDTH-1:0] play_timestamp;
    logic [TIMESTAMP_WIDTH-1:0] loop_length;
    logic rec_en_prev;
    logic play_en_prev;
    
    // edge detection
    logic cymbal_prev, hihat_prev, tom_prev, snare_prev, kick_prev;
    logic cymbal_edge, hihat_edge, tom_edge, snare_edge, kick_edge;
    
    // reset, set previous values
    always_ff @(posedge clk) begin
        if (rst) begin
            cymbal_prev <= 0;
            hihat_prev <= 0;
            tom_prev <= 0;
            snare_prev <= 0;
            kick_prev <= 0;
        end else begin
            cymbal_prev <= cymbal_pressed;
            snare_prev <= snare_pressed;
            hihat_prev <= hihat_pressed;
            tom_prev <= tom_pressed;
            kick_prev <= kick_pressed;
        end
    end
    
    assign cymbal_edge = cymbal_pressed && !cymbal_prev;
    assign hihat_edge = hihat_pressed && !hihat_prev;
    assign tom_edge = tom_pressed && !tom_prev;
    assign snare_edge = snare_pressed && !snare_prev;
    assign kick_edge = kick_pressed && !kick_prev;
    
    // Recording
    always_ff @(posedge clk) begin
        if (rst) begin
            event_count <= 0;
            write_ptr <= 0;
            rec_timestamp <= 0;
            rec_en_prev <= 0;
            rec_done <= 0;
            loop_length <= 0;
        end else begin
            rec_en_prev <= rec_en;
            
            if (rec_en && !rec_en_prev) begin
                write_ptr <= 0;
                rec_timestamp <= 0;
                rec_done <= 0;
                
            end else if (rec_en) begin
                if (sample_tick) begin
                    if (rec_timestamp < 17'd72500) begin
                        rec_timestamp <= rec_timestamp + 1;
                    end else begin
                        rec_done <= 1;
                    end
                end
                
                // Store events with proper priority
                if (write_ptr < MAX_EVENTS - 1) begin
                    if (cymbal_edge) begin
                        event_memory[write_ptr] <= {rec_timestamp, 3'b001};
                        write_ptr <= write_ptr + 1;
                    end else if (hihat_edge) begin
                        event_memory[write_ptr] <= {rec_timestamp, 3'b011};
                        write_ptr <= write_ptr + 1;
                    end else if (tom_edge) begin
                        event_memory[write_ptr] <= {rec_timestamp, 3'b010};
                        write_ptr <= write_ptr + 1;
                    end else if (snare_edge) begin
                        event_memory[write_ptr] <= {rec_timestamp, 3'b110}; 
                        write_ptr <= write_ptr + 1;
                    end else if (kick_edge) begin
                        event_memory[write_ptr] <= {rec_timestamp, 3'b111}; 
                        write_ptr <= write_ptr + 1;
                    end
                end
                
                if (write_ptr >= MAX_EVENTS - 1) begin
                    rec_done <= 1;
                end
                
            end else if (!rec_en && rec_en_prev) begin
                event_count <= write_ptr;
                loop_length <= rec_timestamp;
            end
        end
    end
    
    // laying
    logic [TIMESTAMP_WIDTH-1:0] next_event_time;
    logic [2:0] next_button_id; 
    logic trigger_cymbal, trigger_hihat, trigger_tom, trigger_snare, trigger_kick;
    
    always_ff @(posedge clk) begin
        // reset
        if (rst) begin
            play_ptr <= 0;
            play_timestamp <= 0;
            play_en_prev <= 0;
            trigger_cymbal <= 0;
            trigger_snare <= 0;
            trigger_hihat <= 0;
            trigger_tom <= 0;
            trigger_kick <= 0;
        end else begin
            play_en_prev <= play_en;
            
            trigger_cymbal <= 0;
            trigger_hihat <= 0;
            trigger_tom <= 0;
            trigger_kick <= 0;
            trigger_snare <= 0;
            
            // increment, reset
            if (play_en && !play_en_prev) begin
                play_ptr <= 0;
                play_timestamp <= 0;
            end else if (play_en && event_count > 0 && loop_length > 0) begin
                if (sample_tick) begin
                    play_timestamp <= play_timestamp + 1;
                    
                    if (play_timestamp >= loop_length - 1) begin
                        play_timestamp <= 0;
                        play_ptr <= 0;
                    end
                end
                
                // set next event timestamps and button by reading from memory
                if (play_ptr < event_count) begin
                    next_event_time = event_memory[play_ptr][EVENT_WIDTH-1:3];  // [19:3]
                    next_button_id = event_memory[play_ptr][2:0];               // [2:0]
                    // set buttons pressed
                    if (play_timestamp == next_event_time) begin
                        case (next_button_id)
                            3'b001: trigger_cymbal <= 1;
                            3'b011: trigger_hihat <= 1;
                            3'b010: trigger_tom <= 1; 
                            3'b110: trigger_snare <= 1;
                            3'b111: trigger_kick <= 1; 
                            default: ;
                        endcase
                        
                        play_ptr <= play_ptr + 1;
                    end
                end
                
            end else if (!play_en) begin
                play_ptr <= 0;
                play_timestamp <= 0;
            end
        end
    end
    
    // top module connection
    assign play_cymbal = trigger_cymbal;
    assign play_snare = trigger_snare;
    assign play_hihat = trigger_hihat;
    assign play_tom = trigger_tom;
    assign play_kick = trigger_kick;

endmodule
