`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.04.2017 16:30:34
// Design Name: 
// Module Name: encoder
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


module encoder # (
    parameter INPUT_WIDTH = 10,
    parameter OUTPUT_WIDTH = $clog2(INPUT_WIDTH)
        
)
(
//        input clk,
//        input nreset,
        input [INPUT_WIDTH-1:0] enc_in,
        output [OUTPUT_WIDTH-1:0] enc_out 
    );

    
                        
                        
//    wor [WIDTH-1:0] out_temp; 

//    genvar i,j;
//    generate
//        for (i=0;i<INPUT_WIDTH;i=i+1) 
//            for (j=0;j<OUTPUT_WIDTH;j=j+1)
//                if (i[j])
//                    assign out_temp[j] = enc_in[i];
//    endgenerate

    // Uncomment the following when synthesis tool is VIvado
    wire [OUTPUT_WIDTH-1:0] out_temp;
    
    generate
        if (INPUT_WIDTH == 10) begin: inp_width_10    
            assign out_temp[0] = enc_in[1] || enc_in[3] || enc_in[5] || enc_in[7] || enc_in[9]; 
            assign out_temp[1] = enc_in[2] || enc_in[3] || enc_in[6] || enc_in[7]; 
            assign out_temp[2] = enc_in[4] || enc_in[5] || enc_in[6] || enc_in[7]; 
            assign out_temp[3] = enc_in[8] || enc_in[9]; 
        end
        
        else if (INPUT_WIDTH == 3) begin: inp_width_3
            assign out_temp[0] = enc_in[1]; 
            assign out_temp[1] = enc_in[2]; 
        end
                         
        else if (INPUT_WIDTH == 2) begin: inp_width_2
            assign out_temp = enc_in[1]; 
        end
    endgenerate
                
    // Output register
//    always @(posedge clk or negedge nreset) begin
//        if (~nreset)
//            enc_out <= {OUTPUT_WIDTH{1'b0}};
//        else
//            enc_out <= out_temp;
//    end

    assign enc_out = out_temp;    
endmodule
