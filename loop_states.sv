module loop_states (
    input  logic clk,
    input  logic rst,
    input  logic rec_mode, 
    input  logic play_mode,
    input  logic rec_done,      
    output logic rec_en,
    output logic play_en,
    output logic led_rec,
    output logic led_play
);

    typedef enum logic [1:0] {
        S_IDLE = 2'b00,
        S_REC  = 2'b01,
        S_PLAY = 2'b10
    } state_t;

    state_t state, next_state;

    // states
    always_ff @(posedge clk) begin
        if (rst)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // next state logic
    always_comb begin
        next_state = state;
        
        case(state)
            S_IDLE: begin
                if (rec_mode)
                    next_state = S_REC;
                else if (play_mode)
                    next_state = S_PLAY;
            end
            
            S_REC: begin
                if (rec_done)               
                    next_state = S_IDLE;
                else if (rec_mode)          
                    next_state = S_IDLE;
                else if (play_mode)
                    next_state = S_PLAY;
            end
            
            S_PLAY: begin
                if (play_mode)              
                    next_state = S_IDLE;
                else if (rec_mode)
                    next_state = S_REC;
            end
            
            default: next_state = S_IDLE;
        endcase
    end

    // output logic
    always_comb begin
        rec_en   = (state == S_REC);
        play_en  = (state == S_PLAY);
        led_rec  = (state == S_REC);
        led_play = (state == S_PLAY);
    end

endmodule