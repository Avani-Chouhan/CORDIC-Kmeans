`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 30.03.2017 22:36:45
// Design Name: 
// Module Name: centroid_computation
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This module is used to calculate the centroids given a set of poitns
//                     belonging to a cluster. The inputs are given one component at a time, 
// i.e. If there are N total no. of points in D-dimensional space, the inputs are given in
// the following order: P(0,0), P(1,0) , .... P(N-1,0), P(0,1), P(1,1), .... ,(P(N-1,1), ....... , 
// P(0,D-1), P(1,D-1),....., P(N-1,D-1). After every set of inputs P(0,i) to P(N-1,i) (0<=i<=D-1),
// there is a break of one clock cycle where the data_vld input goes low, to allow the 
// accumulator registers to reset themselves. 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module centroid_computation #(
        parameter DATA_WIDTH = 16,
        parameter DIM_WIDTH = 7,
        parameter NO_OF_CLUSTERS = 5,
        parameter NO_OF_CLUSTERS_WIDTH =3,
        parameter NO_OF_PTS = 10,
        parameter NO_OF_PTS_WIDTH = 4
    ) (
        input clk,
        input nreset,
        input data_vld_in,
        input signed [DATA_WIDTH-1:0] data_in,
        input [NO_OF_CLUSTERS_WIDTH-1:0] cluster_no_in,
        output output_vld,
        output signed [DATA_WIDTH-1:0] centroid_out
    );
            
    reg signed [DATA_WIDTH-1:0] accum [NO_OF_CLUSTERS-1:0];
    reg [NO_OF_PTS_WIDTH-1:0] elements_per_cluster [NO_OF_CLUSTERS-1:0];  
    reg [NO_OF_CLUSTERS_WIDTH-1:0] div_inp_ctr;
    reg data_vld_r;
    reg [NO_OF_PTS_WIDTH-1:0] input_ctr;
    reg stop_wr_elements_per_cluster;
    reg incr_div_inp_ctr;
    reg signed [DATA_WIDTH-1:0] dividend_r [NO_OF_CLUSTERS-1:0]; 
    
    wire input_ctr_last;
    wire [NO_OF_PTS_WIDTH-1:0] elements_per_cluster_incr;
    wire div_inp_ctr_last;
    wire signed [DATA_WIDTH-1:0] sum;
    wire div_inp_vld;

    // divider inputs and outputs
    reg div_en;
    reg signed [DATA_WIDTH-1:0] div_dividend_in;
    reg signed [NO_OF_PTS_WIDTH-1:0] div_divisor_in;
    wire signed [DATA_WIDTH-1:0] div_quotient_out;
    wire div_output_vld;
        
    // Instantiate the divider    
    k_means_div #(
        .DATA_WIDTH (DATA_WIDTH),
        .NO_OF_PTS_WIDTH (NO_OF_PTS_WIDTH)
    ) Divider (    
        .clk (clk),
        .nreset (nreset),
        .div_en (div_en),
        .dividend_in (div_dividend_in),
        .divisor_in (div_divisor_in),
        .quotient_out (div_quotient_out),
        .output_vld (div_output_vld)  
    );

    //--------------------------------------------------------//
    // Data valid register
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            data_vld_r <= 1'b0;
        else
            data_vld_r <= data_vld_in;
    end
    
    // Input counter
    assign input_ctr_last = (input_ctr == NO_OF_PTS[NO_OF_PTS_WIDTH-1:0]-1'b1);
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            input_ctr <= {NO_OF_PTS_WIDTH{1'b0}};
        else begin
            if (input_ctr_last)
                input_ctr <= {NO_OF_PTS_WIDTH{1'b0}};
            else if (data_vld_in)
                input_ctr <= input_ctr + 1'b1;
        end
    end
    
    // No of elements per cluster - Register File, with each
    // location corresponding to one cluster.    
    assign elements_per_cluster_incr = elements_per_cluster[cluster_no_in]+1'b1;
    integer i;
    always @(posedge clk or negedge nreset) begin   
        if (~nreset)
            for (i=0;i<NO_OF_CLUSTERS;i=i+1)
                elements_per_cluster[i] <= {NO_OF_PTS_WIDTH{1'b0}};
        else begin
            if (div_inp_ctr_last && ~data_vld_in && ~data_vld_r)
                for (i=0;i<NO_OF_CLUSTERS;i=i+1)
                    elements_per_cluster[i] <= {NO_OF_PTS_WIDTH{1'b0}};
            
            else if (data_vld_in && 
                  ~stop_wr_elements_per_cluster)
                elements_per_cluster[cluster_no_in] <= elements_per_cluster_incr;                   
        end
    end
            
    // The following register indicates when to stop writing 
    // into the register filw storing no. of elements in each
    // cluster. This is because, after one set of NO_OF_PTS
    // inputs have arrivied, the cluster_no_in value from the 
    // next set onwards will be repeated. So, storing them
    // once is enough.
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            stop_wr_elements_per_cluster <= 1'b0;
        else begin
            if (~data_vld_in && ~data_vld_r)
                stop_wr_elements_per_cluster <= 1'b0;
            else if (input_ctr_last)
                stop_wr_elements_per_cluster <= 1'b1;
        end
    end
    
    //integer i;
    
    // Accumulator 
    // This net adds the incoming vector component 
    // to the corresponding value in accum. 
    assign sum = accum[cluster_no_in] + data_in;
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            for (i=0;i<NO_OF_CLUSTERS;i=i+1)
                accum[i] <= {DATA_WIDTH{1'b0}};
        
        else begin
            if (~data_vld_in && data_vld_r) // detecting the data_vld_in low pulse.         
                for (i=0;i<NO_OF_CLUSTERS;i=i+1)
                    accum[i] <= {DATA_WIDTH{1'b0}};
            else if (data_vld_in)
                accum[cluster_no_in] <= sum;
        end
    end
    
    // Counter to keep track of how many inputs have gone to divider.
    assign div_inp_ctr_last = (div_inp_ctr == NO_OF_CLUSTERS-1'b1);
        
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            incr_div_inp_ctr <= 1'b0;
        else begin
            if (~data_vld_in && data_vld_r)
                incr_div_inp_ctr <= 1'b1;
            else if (div_inp_ctr_last)
                incr_div_inp_ctr <= 1'b0;
        end
    end

    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            div_inp_ctr <= {NO_OF_CLUSTERS_WIDTH{1'b0}};
        else begin
            if (div_inp_ctr_last)
                div_inp_ctr <= {NO_OF_CLUSTERS_WIDTH{1'b0}};
            else if (incr_div_inp_ctr)
                div_inp_ctr <= div_inp_ctr + 1'b1;
        end
    end                                          

    // Dividend registers
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            for (i=0;i<NO_OF_CLUSTERS;i=i+1)
                dividend_r[i] <= {DATA_WIDTH{1'b0}};
        else begin
            if (~data_vld_in && data_vld_r)
                for (i=0;i<NO_OF_CLUSTERS;i=i+1)
                    dividend_r[i] <= accum[i];            
        end
    end
                
    // DIvider input signals
    always @(posedge clk or negedge nreset) begin
        if (~nreset) 
            div_en <= 1'b0;
        else
            div_en <= incr_div_inp_ctr;
    end
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            div_dividend_in <= {DATA_WIDTH{1'b0}};
            div_divisor_in <= {DATA_WIDTH{1'b0}};
        end
        
        else if (incr_div_inp_ctr) begin
            div_dividend_in <= dividend_r[div_inp_ctr];
            div_divisor_in <= elements_per_cluster[div_inp_ctr];
        end
    end        
    
    // Outputs
    assign output_vld = div_output_vld;
    assign centroid_out = div_quotient_out;
            
endmodule
