`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.03.2017 17:19:26
// Design Name: 
// Module Name: cluster_computation
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

module cluster_computation #(
        parameter DATA_WIDTH = 16,
        parameter NO_OF_CLUSTERS = 5,
        parameter NO_OF_CLUSTERS_WIDTH =3
    ) (
        input clk,
        input nreset,
        input data_vld_in,
        input signed [DATA_WIDTH-1:0] data_in,
        output reg output_vld,
        output [NO_OF_CLUSTERS_WIDTH-1:0] cluster_no_out
    );
                            
    reg signed [DATA_WIDTH-1:0] min;
    reg [NO_OF_CLUSTERS_WIDTH-1:0] input_ctr;
    reg [NO_OF_CLUSTERS_WIDTH-1:0] cluster_no;
    
    wire input_ctr_last;
    
    //----------------------------------------------------------------------------//
    // Input counter
    assign input_ctr_last = (input_ctr == NO_OF_CLUSTERS-1'b1);
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) 
            input_ctr <= {NO_OF_CLUSTERS_WIDTH{1'b0}};
        else begin
            if (input_ctr_last)
                input_ctr <= {NO_OF_CLUSTERS_WIDTH{1'b0}};
            else if (data_vld_in)
                input_ctr <= input_ctr + 1'b1;
        end
    end
                
    // Minimum distance calculation
    always @(posedge clk or negedge nreset) begin
        if (~nreset) 
            min <= {DATA_WIDTH{1'b0}};
        else if (data_vld_in && ((min > data_in) ||
                (input_ctr == {NO_OF_CLUSTERS_WIDTH{1'b0}})))
            min <= data_in;
    end         
    
    // Updating the cluster
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            cluster_no <= {NO_OF_CLUSTERS_WIDTH{1'b0}};
        else if (data_vld_in && ((min > data_in) ||
                   (input_ctr == {NO_OF_CLUSTERS_WIDTH{1'b0}})))
            cluster_no <= input_ctr;
    end           
                    
    // Outputs
    assign cluster_no_out = cluster_no;
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            output_vld <= 1'b0;
        else 
            output_vld <= input_ctr_last;
    end         
                   
endmodule
