module top (
    input logic button_cymbal,
    input logic button_snare,
    input logic button_hihat,
    input logic button_tom,
    input logic button_kick,
    input logic btn_rec,
    input logic btn_play,
    output logic led_rec_top,
    output logic led_play_top,
    output logic pwm_out1
);

    logic clock;
    SB_HFOSC #(
        .CLKHF_DIV("0b01") // 48 MHz
    ) osc (
        .CLKHFPU(1'b1),
        .CLKHFEN(1'b1),
        .CLKHF(clock)
    );

    // Sample rate generator
    logic sample_tick;
    logic [49:0] tick_counter;
    
    parameter integer CLOCK_FREQ  = 48000000;
    parameter integer SAMPLE_RATE = 14500;
    parameter integer TICK_DIV    = CLOCK_FREQ / SAMPLE_RATE - 1;

    always_ff @(posedge clock) begin
        if (tick_counter == TICK_DIV) begin
            tick_counter <= 0;
            sample_tick <= 1;
        end else begin
            tick_counter <= tick_counter + 1;
            sample_tick <= 0;
        end
    end

    // ===== BUTTON DEBOUNCERS =====
    logic cymbal_pressed;
    logic snare_pressed;
    logic hihat_pressed;
    logic tom_pressed;
    logic kick_pressed;
    
    button_debouncer cymbal_debounce (
        .clk(clock),
        .button_raw(!button_cymbal),
        .button_pressed(cymbal_pressed)
    );

    button_debouncer hihat_debounce (
        .clk(clock),
        .button_raw(!button_hihat),
        .button_pressed(hihat_pressed)
    );

    button_debouncer tom_debounce (
        .clk(clock),
        .button_raw(!button_tom),
        .button_pressed(tom_pressed)
    );

    button_debouncer snare_debounce (
        .clk(clock),
        .button_raw(!button_snare),
        .button_pressed(snare_pressed)
    );

    button_debouncer kick_debounce (
        .clk(clock),
        .button_raw(!button_kick),
        .button_pressed(kick_pressed)
    );

    logic [11:0] addr;
    logic playing;
    logic [2:0] current_sound;
    logic [2:0] current_sound_delayed;
    logic [11:0] max_addr;
    
    // NEW: Playback triggers from looper
    logic play_cymbal_trigger;
    logic play_hihat_trigger;
    logic play_tom_trigger;
    logic play_snare_trigger;
    logic play_kick_trigger;
    
    logic cymbal_trigger;
    logic snare_trigger;
    logic hihat_trigger;
    logic tom_trigger;
    logic kick_trigger;
    
    assign cymbal_trigger = play_en ? play_cymbal_trigger : cymbal_pressed;
    assign hihat_trigger = play_en ? play_hihat_trigger : hihat_pressed;
    assign tom_trigger = play_en ? play_tom_trigger : tom_pressed;
    assign snare_trigger = play_en ? play_snare_trigger : snare_pressed;
    assign kick_trigger = play_en ? play_kick_trigger : kick_pressed;
    
    always_ff @(posedge clock) begin
        current_sound_delayed <= current_sound;
        
        if (cymbal_trigger && !playing) begin
            addr <= 0;
            playing <= 1;
            current_sound <= 3'd1;
            max_addr <= 12'd2450;
        end else if (hihat_trigger && !playing) begin
            addr <= 0;
            playing <= 1;
            current_sound <= 3'd2;
            max_addr <= 12'd485;
        end else if (tom_trigger && !playing) begin
            addr <= 0;
            playing <= 1;
            current_sound <= 3'd3;
            max_addr <= 12'd3210;
        end else if (snare_trigger && !playing) begin
            addr <= 0;
            playing <= 1;
            current_sound <= 3'd4;
            max_addr <= 12'd728;
        end else if (kick_trigger && !playing) begin
            addr <= 0;
            playing <= 1;
            current_sound <= 3'd4;
            max_addr <= 12'd2028;
        end else if (sample_tick && playing) begin
            if (addr == max_addr) begin
                addr <= 0;
                playing <= 0;
                current_sound <= 3'd0;
            end else begin
                addr <= addr + 1;
            end
        end
    end

    // read from ROMs
    logic [7:0] cymbal_sample;
    logic [7:0] hihat_sample;
    logic [7:0] tom_sample;
    logic [7:0] snare_sample;
    logic [7:0] kick_sample;
    logic [7:0] current_sample;
    
    audio_rom_cymbal cymbal_rom (
        .clk(clock),
        .addr(addr),
        .data_out(cymbal_sample)
    );
    
    audio_rom_hihat hihat_rom (
        .clk(clock),
        .addr(addr),
        .data_out(hihat_sample)
    );

    audio_rom_tom tom_rom (
        .clk(clock),
        .addr(addr),
        .data_out(tom_sample)
    );

    audio_rom_snare snare_rom (
        .clk(clock),
        .addr(addr),
        .data_out(snare_sample)
    );

    audio_rom_kick kick_rom (
        .clk(clock),
        .addr(addr),
        .data_out(kick_sample)
    );
    
    // Select which drum sample to output
    always_comb begin
        case (current_sound_delayed)
            3'd1: current_sample = cymbal_sample;
            3'd2: current_sample = hihat_sample;
            3'd3: current_sample = tom_sample;
            3'd4: current_sample = snare_sample;
            3'd5: current_sample = kick_sample;
            default: current_sample = 8'd128;  // Silence
        endcase
    end
    
    // reset
    logic [3:0] rst_counter = 4'b0;
    logic rst;
    
    always_ff @(posedge clock) begin
        if (rst_counter != 4'b1111)
            rst_counter <= rst_counter + 1;
    end
    
    assign rst = (rst_counter != 4'b1111);
    
    // edge detection for rec/play buttons
    logic rec_prev = 1'b0, play_prev = 1'b0;
    logic rec_mode, play_mode;
    
    always_ff @(posedge clock) begin
        if (rst) begin
            rec_prev  <= 1'b0;
            play_prev <= 1'b0;
        end else begin
            rec_prev  <= btn_rec;
            play_prev <= btn_play;
        end 
    end

    assign rec_mode  = btn_rec  & ~rec_prev;
    assign play_mode = btn_play & ~play_prev;
    
    logic rec_en, play_en;
    logic rec_done;

    memory seq_mem (
        .clk(clock),
        .rst(rst),
        .rec_en(rec_en),
        .play_en(play_en),
        .sample_tick(sample_tick),
        .cymbal_pressed(cymbal_pressed),
        .hihat_pressed(hihat_pressed),
        .tom_pressed(tom_pressed),
        .kick_pressed(kick_pressed),
        .snare_pressed(snare_pressed),
        .play_cymbal(play_cymbal_trigger),
        .play_hihat(play_hihat_trigger),
        .play_tom(play_tom_trigger),
        .play_kick(play_kick_trigger),
        .play_snare(play_snare_trigger),
        .rec_done(rec_done)
    );

    loop_states states_inst (
        .clk(clock),
        .rst(rst),
        .rec_mode(rec_mode),
        .play_mode(play_mode),
        .rec_done(rec_done),
        .rec_en(rec_en),
        .play_en(play_en),
        .led_rec(led_rec_top),
        .led_play(led_play_top)
    );
    
    pwm_dac dac (
        .clk(clock),
        .sample(current_sample),
        .pwm_out(pwm_out1)
    );

endmodule
