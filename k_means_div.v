`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.03.2017 15:57:37
// Design Name: 
// Module Name: k_means_div
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module k_means_div #(
   parameter DATA_WIDTH = 16,
   parameter NO_OF_PTS_WIDTH = 4
)

(
        input clk,
        input nreset,
        input div_en,
        input signed [DATA_WIDTH-1:0] dividend_in,
        input [NO_OF_PTS_WIDTH-1:0] divisor_in,
        output reg signed [DATA_WIDTH-1:0] quotient_out,
        output reg output_vld            
    );
    
   
    
//    3-0010101010101010- 2,4,6,8,10,12,14
//    4-0010000000000000-  2
//    5-0001100110011001 - 3,4,7,8,11,12,15
//    6-0001010101010101 - 3,5,7,9,11,13,15
//    7-0001001001001001 - 3, 6,9,12,15
//    8-0001000000000000 - 3
//    9-0000111000111000 - 4,5,6,10,11,12
//   10-0000110011001100 - 4,5,8,9,12,13

//    wire signed [DATA_WIDTH-1:0] quotient_temp [10:0];
    
//    // divide by 0 or 1 - just return the dividend itself.
//    assign quotient_temp[0] = dividend_in;  
//    assign quotient_temp[1] = dividend_in;  
    
//    // divide by 2 - right shift by 1 bit.
//    assign quotient_temp[2] = {dividend_in[DATA_WIDTH-1],dividend_in[DATA_WIDTH-1:1]};     
    
//    // divide by 3.
//    assign quotient_temp[3] = {{2{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:2]} + 
//                                               {{4{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:4]} +
//                                               {{6{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:6]} +
//                                               {{8{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:8]} +
//                                               {{10{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:10]} +
//                                               {{12{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:12]} +
//                                               {{14{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:14]};    

//    // divide by 4 - right shift by 2 bits.
//    assign quotient_temp[4] = {{2{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:2]};
    
//    // divide by 5
//    assign quotient_temp[5] = {{3{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:3]} +
//                                               {{4{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:4]} +
//                                               {{7{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:7]} +
//                                               {{8{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:8]} +
//                                               {{11{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:11]} +
//                                               {{12{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:12]} +
//                                               {{15{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:15]};    

//    // divide by 6
//    assign quotient_temp[6] = {{3{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:3]} +
//                                               {{5{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:5]} +
//                                               {{7{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:7]} +
//                                               {{9{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:9]} +
//                                               {{11{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:11]} +
//                                               {{13{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:13]} +
//                                               {{15{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:15]};    

//    // divide by 7
//    assign quotient_temp[7] = {{3{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:3]} +
//                                               {{6{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:6]} +
//                                               {{9{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:9]} +
//                                               {{12{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:12]} +
//                                               {{15{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:15]};    
     
//    // divide by 8 - right shift by 3 bits.
//    assign quotient_temp[8] = {{3{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:3]};     

//    // divide by 9
//    assign quotient_temp[9] = {{4{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:4]} +
//                                               {{5{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:5]} +
//                                               {{6{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:6]} +
//                                               {{10{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:10]} +
//                                               {{11{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:11]} +
//                                               {{12{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:12]};    

//    // divide by 10
//    assign quotient_temp[10] = {{4{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:4]} +
//                                                 {{5{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:5]} +
//                                                 {{8{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:8]} +
//                                                 {{9{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:9]} +
//                                                 {{12{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:12]} +
//                                                 {{13{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:13]};    
                                               
                                               
    //------------------------------------------------------------------------------//
    reg signed [DATA_WIDTH-1:0] quotient_temp [10:0];
    
    integer i;
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            for (i=0;i<11;i=i+1)
                quotient_temp[i] <= {DATA_WIDTH{1'b0}};
        end
        
        else if (div_en) begin
            // divide by 0 or 1 - just return the dividend itself.
            quotient_temp[0] <= dividend_in;  
            quotient_temp[1] <= dividend_in;  
            
            // divide by 2 - right shift by 1 bit.
            quotient_temp[2] <= {dividend_in[DATA_WIDTH-1],dividend_in[DATA_WIDTH-1:1]};     
            
            // divide by 3.
            quotient_temp[3] <= {{2{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:2]} + 
                                              {{4{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:4]} +
                                              {{6{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:6]} +
                                              {{8{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:8]} +
                                              {{10{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:10]} +
                                              {{12{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:12]} +
                                              {{14{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:14]};    
        
            // divide by 4 - right shift by 2 bits.
            quotient_temp[4] <= {{2{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:2]};
            
            // divide by 5
            quotient_temp[5] <= {{3{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:3]} +
                                              {{4{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:4]} +
                                              {{7{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:7]} +
                                              {{8{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:8]} +
                                              {{11{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:11]} +
                                              {{12{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:12]} +
                                              {{15{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:15]};    
        
            // divide by 6
            quotient_temp[6] <= {{3{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:3]} +
                                              {{5{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:5]} +
                                              {{7{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:7]} +
                                              {{9{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:9]} +
                                              {{11{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:11]} +
                                              {{13{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:13]} +
                                              {{15{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:15]};    
        
            // divide by 7
            quotient_temp[7] <= {{3{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:3]} +
                                              {{6{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:6]} +
                                              {{9{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:9]} +
                                              {{12{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:12]} +
                                              {{15{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:15]};    
             
            // divide by 8 - right shift by 3 bits.
            quotient_temp[8] <= {{3{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:3]};     
        
            // divide by 9
            quotient_temp[9] <= {{4{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:4]} +
                                              {{5{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:5]} +
                                              {{6{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:6]} +
                                              {{10{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:10]} +
                                              {{11{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:11]} +
                                              {{12{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:12]};    
        
            // divide by 10
            quotient_temp[10] <= {{4{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:4]} +
                                                {{5{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:5]} +
                                                {{8{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:8]} +
                                                {{9{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:9]} +
                                                {{12{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:12]} +
                                                {{13{dividend_in[DATA_WIDTH-1]}},dividend_in[DATA_WIDTH-1:13]};                   
        end
    end
                
    reg enable_r;
    reg signed [NO_OF_PTS_WIDTH-1:0] divisor_r;
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            enable_r <= 1'b0;
            divisor_r <= {DATA_WIDTH{1'b0}};
        end
        
        else begin
            enable_r <= div_en;
            
            if (div_en)
                divisor_r <= divisor_in;
        end        
    end
                                                   
    //------------Outputs------------//
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            output_vld <= 1'b0;
            quotient_out <= {DATA_WIDTH{1'b0}};
        end
        
        else begin
            output_vld <= enable_r;
            
            if (enable_r)
                quotient_out <= quotient_temp[divisor_r];
        end
    end        
       
endmodule
