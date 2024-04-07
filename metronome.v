`timescale 1ns / 1ps

module metronome(
    input clk,                             
    input reset,                           
    input [3:0] tempo_switches, 
    input video_on,                         
    input [9:0] x, y,                       
    output reg [11:0] rgb                   
    );
    
    parameter X_MAX = 639;                    // right border of display area
    parameter Y_MAX = 479;                    // bottom border of display area
    parameter PENDULUM_COLOR_RGB = 12'h0FF;   // yellow
    parameter BACKGROUND_COLOR_RGB = 12'h000; // black 
    parameter PENDULUM_SIZE = 64;             // width of pendulum sides in pixels
    parameter PENDULUM_VELOCITY_POS = 1;      // set position change value for positive direction
    parameter PENDULUM_VELOCITY_NEG = -1;     // set position change value for negative direction  

    
    // create a 60Hz refresh tick at the start of vsync 
    wire refresh_tick;
    assign refresh_tick = ((y == 481) && (x == 0)) ? 1 : 0;
    
    // pendulum boundaries and position
    wire [9:0] sq_x_l, sq_x_r;             
    wire [9:0] sq_y_t, sq_y_b;             
    
    reg [9:0] sq_x_reg, sq_y_reg;           // regs to track left, top position
    wire [9:0] sq_x_next, sq_y_next;        
    
    reg [9:0] x_delta_reg, y_delta_reg;     // track pendulum speed
    reg [9:0] x_delta_next, y_delta_next;   
    
    // register control
    always @(posedge clk or posedge reset)
        if(reset) begin
            sq_x_reg <= 0;
            sq_y_reg <= Y_MAX - PENDULUM_SIZE;
            x_delta_reg <= 10'h002;
            y_delta_reg <= 10'h002;
        end
        else begin
            sq_x_reg <= sq_x_next;
            sq_y_reg <= sq_y_next;
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
        end
    
    // pendulum boundaries
    assign sq_x_l = sq_x_reg;                   
    assign sq_y_t = sq_y_reg;                  
    assign sq_x_r = sq_x_l + PENDULUM_SIZE - 1;   
    assign sq_y_b = sq_y_t + PENDULUM_SIZE - 1;   
    
    // pendulum status signal
    wire sq_on;
    assign sq_on = (sq_x_l <= x) && (x <= sq_x_r) &&
                   (sq_y_t <= y) && (y <= sq_y_b);
                    
    // new pendulum position
    assign sq_x_next = (refresh_tick) ? sq_x_reg + x_delta_reg : sq_x_reg;
    assign sq_y_next = sq_y_reg;
    
    // new pendulum velocity 
    always @* begin
        x_delta_next = x_delta_reg;
        y_delta_next = y_delta_reg;

        if(sq_x_l < 1)  // collide with left display edge
            x_delta_next = PENDULUM_VELOCITY_POS + tempo_switches[0] + tempo_switches[1] + tempo_switches[2] + tempo_switches[3];     
        else if(sq_x_r > X_MAX)
            x_delta_next = PENDULUM_VELOCITY_NEG - tempo_switches[0] - tempo_switches[1] - tempo_switches[2] - tempo_switches[3];     
    end
    
    // RGB control
    always @*
        if(~video_on)
            rgb = BACKGROUND_COLOR_RGB;
        else
            if(sq_on)
                rgb = PENDULUM_COLOR_RGB;
            else
                rgb = BACKGROUND_COLOR_RGB;
    
endmodule

