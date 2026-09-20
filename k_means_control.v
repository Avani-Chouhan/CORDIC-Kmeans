`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.03.2017 15:01:04
// Design Name: 
// Module Name: k_means_control
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This K-Means clustering is designed specific to SCICA, where 
//                     the dimension of the points (D) is very high (viz. 128, 256, etc) 
// as compared to the number of points (N) (viz. 6,8,10, etc). Therefore, it works
// by using one memory for each point, containing all the components of that
// particular point. For instance, considering 10 points each of 128 dimensions,
// there are 10 memories of size 128 X DATA_WIDTH. 
// In conventional k-Means clustering, N >> D, and hence there will be D memories
// of size N X DATA_WIDTH. The logic of the design in that case will remain similar
// to the present one, except for memory read/write patterns, which have to be 
// modified accordingly.
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//`include "C:/Users/ashle/Downloads/kmeans_codes/kmeans_rtl_swati/constants.v"
module k_means_control #(
        parameter DATA_WIDTH = 16,
        parameter DIM = 128,
        parameter NO_OF_PTS = 10,
        parameter NO_OF_CLUSTERS = 5,
        parameter CORDIC_LATENCY = 18,
         parameter CONV_THRESH = 1000,
         parameter DIM_WIDTH = clogb2(DIM-1),
         parameter NO_OF_CLUSTERS_WIDTH = clogb2(NO_OF_CLUSTERS-1),
        parameter NO_OF_PTS_WIDTH = clogb2(NO_OF_PTS-1),
        parameter CONV_CHK_CTR_WIDTH = clogb2(CORDIC_LATENCY-1)
          
    ) (
        input clk,
        input nreset,
        input data_vld_in,
        input signed [DATA_WIDTH-1:0] data_in,
        output reg output_vld,
        output reg [NO_OF_CLUSTERS_WIDTH-1:0] cluster_no_out,
        
        // Memory Signals
        // Data Memory
        input signed [DATA_WIDTH-1:0] data_mem_rdata,    
        input data_mem_rdata_vld,

        output reg [NO_OF_PTS-1:0] data_mem_wren,
        output reg [DIM_WIDTH-1:0] data_mem_wraddr,        
        output reg signed [DATA_WIDTH-1:0] data_mem_wrdata,
        output [NO_OF_PTS-1:0] data_mem_rden,
        output reg [DIM_WIDTH-1:0] data_mem_rdaddr,    
        
        // Current Centroid memory          
        input signed [DATA_WIDTH-1:0] centroid_rdata0_in,
        input signed [DATA_WIDTH-1:0] centroid_rdata1_in,
        input [1:0] centroid_rdata_vld,
            
        output reg [NO_OF_CLUSTERS-1:0] centroid_wren,
        output reg [DIM_WIDTH-1:0] centroid_wraddr,        
        output reg signed [DATA_WIDTH-1:0] centroid_wrdata,
        output reg [NO_OF_CLUSTERS-1:0] centroid_rden,
        output reg [DIM_WIDTH-1:0] centroid_rdaddr0,        
        output reg [DIM_WIDTH-1:0] centroid_rdaddr1,        
        output centroid_rdaddr1_vld,      
        
        // Old Centroid memory          
        input signed [DATA_WIDTH-1:0] centroid_old_rdata0_in,        
        input signed [DATA_WIDTH-1:0] centroid_old_rdata1_in,        
        
        output reg [NO_OF_CLUSTERS-1:0] centroid_old_wren,
        output reg [DIM_WIDTH-1:0] centroid_old_wraddr,        
        output reg signed [DATA_WIDTH-1:0] centroid_old_wrdata,
        output [NO_OF_CLUSTERS-1:0] centroid_old_rden,
        
        // Temporary memory
        input signed [DATA_WIDTH-1:0] temp_mem_rdata,
        input temp_mem_rdata_vld,
        output reg temp_mem_wren,
        output reg [DIM_WIDTH-1:0] temp_mem_wraddr,        
        output reg signed [DATA_WIDTH-1:0] temp_mem_wrdata,
        output reg temp_mem_rden,
        output reg [DIM_WIDTH-1:0] temp_mem_rdaddr,
        
        // Cluster Computation
        input cluster_comp_opvld,    
        input [NO_OF_CLUSTERS_WIDTH-1:0] cluster_comp_out,        
        output reg cluster_comp_data_vld,
        output reg signed [DATA_WIDTH-1:0] cluster_comp_data_in,
        
        // Centroid computation
        input centroid_comp_opvld,
        input signed [DATA_WIDTH-1:0] centroid_comp_out,
        output reg centroid_comp_data_vld_in,
        output reg signed [DATA_WIDTH-1:0] centroid_comp_data_in,
        output reg [NO_OF_CLUSTERS_WIDTH-1:0] centroid_comp_cluster_no_in,
        
        // CORDIC Vectoring Mode
        input cordic_vec_opvld,
        input signed [DATA_WIDTH-1:0] cordic_vec_xout,
        output reg cordic_vec_en,
        output reg signed [DATA_WIDTH-1:0] cordic_vec_xin,
        output reg signed [DATA_WIDTH-1:0] cordic_vec_yin                
    );
                            
    // The following function calculates 
    // the ceiling of log2 of an integer.
    function integer clogb2;
        input integer depth;
            for (clogb2=0; depth>0; clogb2=clogb2+1)
                depth = depth >> 1;
    endfunction
    
    //localparam DIM_WIDTH = clogb2(DIM-1),
                     // NO_OF_CLUSTERS_WIDTH = clogb2(NO_OF_CLUSTERS-1),
                     // NO_OF_PTS_WIDTH = clogb2(NO_OF_PTS-1);
    
    //-------------------------------------------------------------//
    reg [NO_OF_PTS-1:0] data_mem_rden_r;
    reg data_mem_rden_mask;
    reg mem_rd_level0;
    reg signed [DATA_WIDTH-1:0] data_mem_rdata_r;
    reg data_mem_rdata_vld_r;
    reg [DIM_WIDTH-1:0] cordic_vec_level_ctr;
    reg [6:0] iter_count;
    reg [CONV_CHK_CTR_WIDTH-1:0] conv_chk_ctr;
    reg incr_conv_chk_ctr;
    reg [1:0] centroid_comp_opvld_r;
    reg signed [DATA_WIDTH-1:0] centroid_comp_out_r;
    reg send_centr_comp_inp;
    reg cordic_vec_opvld_r;
    reg [1:0] centroid_rdata_vld_r;
    reg signed [DATA_WIDTH-1:0] centroid_r; 
    reg signed [DATA_WIDTH-1:0] centroid_old_r; 
    reg centroid_r_wrmux_sel;
    reg cvm_inp_complete;
    reg [NO_OF_CLUSTERS_WIDTH-1:0] centr_ctr;
    reg centr_ctr_last_r;
    reg [NO_OF_PTS_WIDTH-1:0] vec_rd_ctr;    // "vec" and "point" are the same here and will be used interchangeably.
    reg vec_rd_ctr_last_r;
    
    wire shift_data_mem_rden;   
    wire stop_data_mem_rden;    
    wire data_mem_rdaddr_last;
    wire temp_mem_wraddr_last;
    wire temp_mem_rdaddr_last;
    wire centroid_wraddr_last;
    wire centroid_rdaddr0_last;
    wire centroid_old_wraddr_last;
    wire centr_ctr_last;
    wire centr_ctr_zero;
    wire conv_chk_ctr_last;
    wire conv_chk_complete;
    wire conv_rchd;
    wire conv_not_rchd;                            
    wire cordic_vec_level_last;
    wire incr_vec_level_ctr;
    wire vec_rd_ctr_last;
    // Start and end indicators
    wire start_init_centroid;
    wire start_cluster_comp;
    wire start_centroid_comp;
    wire start_conv_chk;
    wire init_centroid_complete;
    wire cluster_comp_complete;
    wire centroid_comp_complete;
    wire output_complete;    
    wire [2*DIM_WIDTH-1:0]centroid_rdaddr;
    //-------------------------------------------------------------//

    ////////////////////////////////////////////////////////////
    //------------------------FSM--------------------------//
    ////////////////////////////////////////////////////////////

    localparam IDLE = 3'b000,                       
                      INPUTS = 3'b001,  
                      INIT_CENTROID = 3'b010,                
                      CLUSTER_COMP = 3'b011,        // compute the distances and hence the clusters
                      CENTROID_COMP = 3'b100,      // Compute the new centroids 
                      CONV_CHK = 3'b101,               // Check for convergence of centroid 
                      OUTPUTS = 3'b110;
    
    reg [2:0] cur_state;
    reg [2:0] next_state;
    
    // Combinational Logic to determine next state
    always @* begin
        next_state = 3'b000;
        
        case (cur_state) 
            IDLE: 
                begin   
                    if (data_vld_in)
                        next_state = INPUTS;
                    else
                        next_state = IDLE;
                end
                
            INPUTS: 
                begin
                    if (~data_vld_in)
                        next_state = INIT_CENTROID;
                    else
                        next_state = INPUTS;
                end
            
            INIT_CENTROID:
                begin
                    if (init_centroid_complete)
                        next_state = CLUSTER_COMP;
                    else
                        next_state = INIT_CENTROID;
                end
                
            CLUSTER_COMP: 
                begin
                    if (cluster_comp_complete)
                        next_state = CENTROID_COMP;
                    else
                        next_state = CLUSTER_COMP;
                end
                
            CENTROID_COMP:
                begin
                    if (centroid_comp_complete) begin
                        if (iter_count == {7{1'b0}})
                            next_state = CLUSTER_COMP;
                        else
                            next_state = CONV_CHK;
                    end
                    
                    else
                        next_state = CENTROID_COMP; 
                end
                
            CONV_CHK: 
                begin
                    if (conv_rchd)
                        next_state = OUTPUTS;
                    else if (conv_not_rchd)
                        next_state = CLUSTER_COMP;
                    else
                        next_state = CONV_CHK;
                 end
             
            OUTPUTS: 
                begin
                    if (output_complete)
                        next_state = IDLE;
                    else
                        next_state = OUTPUTS;                        
                end
        endcase
    end
    
    // Sequential logic - Current state takes the value of next state.
    always @(posedge clk or negedge nreset) begin
        if (~nreset) 
            cur_state <= 3'b000;
        else
            cur_state <= next_state;
    end
    
    //-------------------------------------------------------------------------------//
    // Write input data to memory.
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            data_mem_wren <= {NO_OF_PTS{1'b0}};
            data_mem_wraddr <= {DIM_WIDTH{1'b0}};
            data_mem_wrdata <= {DATA_WIDTH{1'b0}};
        end
        
        else begin
            if (data_vld_in) begin
                data_mem_wrdata <= data_in;

                if (cur_state == IDLE)
                    data_mem_wren <= {{NO_OF_PTS-1{1'b0}},1'b1};
                else if (data_mem_wraddr == DIM[DIM_WIDTH-1:0]-1'b1)
                    data_mem_wren <=  {data_mem_wren[NO_OF_PTS-2:0],1'b0};
                                
                if (cur_state == INPUTS)
                    data_mem_wraddr <= data_mem_wraddr + 1'b1;                
            end
            
            else if (data_mem_wren[NO_OF_PTS-1])
                data_mem_wren <= {NO_OF_PTS{1'b0}};
        end
    end
    
    //------------------------------------------------------------------------------//
    // Iteration Counter
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            iter_count <= {7{1'b0}};
        else begin
            if (conv_rchd || (conv_not_rchd && 
                (iter_count == {7{1'b1}})))
                iter_count <= {7{1'b0}};
            else if (conv_not_rchd ||
                       ((cur_state == CENTROID_COMP) && 
                       (next_state == CLUSTER_COMP)))
                iter_count <= iter_count + 1'b1;
        end
    end
                
    //-----------------------------------------------------------------------//
         
    //////////////////////////////////////////////////////////////////////////
    //-------------------Data Memory Read---------------------//
    /////////////////////////////////////////////////////////////////////////
    
    wire load_data_rden;
    assign load_data_rden = start_init_centroid || 
                                              start_cluster_comp || 
                                              start_centroid_comp;         
                                              
    assign shift_data_mem_rden =  ((cur_state == CLUSTER_COMP) && 
                                                        ((mem_rd_level0 && centr_ctr_last_r) ||
                                                         (~mem_rd_level0 && centr_ctr_last))) ||
                                                      ((cur_state == CENTROID_COMP) && 
                                                        ~data_mem_rden_mask && send_centr_comp_inp) ||
                                                      ((cur_state == INIT_CENTROID) && data_mem_rdaddr_last);
                        
    assign stop_data_mem_rden = (vec_rd_ctr_last && data_mem_rdaddr_last && 
                                                     ((cur_state == CENTROID_COMP) ||
                                                     ((cur_state == CLUSTER_COMP) && centr_ctr_last))) ||
                                                     ((cur_state == INIT_CENTROID) &&    
                                                     data_mem_rdaddr_last && data_mem_rden_r[NO_OF_CLUSTERS-1]); 
                                                                 
    // Data Memory Read Enable
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            data_mem_rden_r <= {NO_OF_PTS{1'b0}};
        
        else begin
            if (load_data_rden)
                data_mem_rden_r <= {{NO_OF_PTS-1{1'b0}},1'b1};
            
            else begin
                if (stop_data_mem_rden)
                    data_mem_rden_r <= {NO_OF_PTS{1'b0}};    
                else if (shift_data_mem_rden)    
                    data_mem_rden_r <= {data_mem_rden_r[NO_OF_PTS-2:0],data_mem_rden_r[NO_OF_PTS-1]};
            end
        end
    end

    // Mask for data_mem_rden
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            data_mem_rden_mask <= 1'b0;
        else begin
            if (cur_state == CLUSTER_COMP) begin
                if ((mem_rd_level0 && data_mem_rdaddr[0]) || 
                    (~mem_rd_level0 && centr_ctr_zero))    
                    data_mem_rden_mask <= 1'b1;
                
                else if ((mem_rd_level0 && centr_ctr_last_r) ||  
                             (~mem_rd_level0 && centr_ctr_last))
                    data_mem_rden_mask <= 1'b0;
            end
            
            if (cur_state == CENTROID_COMP) begin   
                if (send_centr_comp_inp && vec_rd_ctr_last)
                    data_mem_rden_mask <= 1'b1;                
                else 
                    data_mem_rden_mask <= 1'b0;
            end
        end
    end
    
    // The actual data_mem_rden - After applying the mask.
    assign data_mem_rden = data_mem_rden_r & ~{NO_OF_PTS{data_mem_rden_mask}};
    
    // Data memory read address
    assign data_mem_rdaddr_last = (data_mem_rdaddr == DIM[DIM_WIDTH-1:0]-1'b1);
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) 
            data_mem_rdaddr <= {DIM_WIDTH{1'b0}};
        else begin
            if (cur_state == INIT_CENTROID) begin
                if (data_mem_rdaddr_last)
                    data_mem_rdaddr <= {DIM_WIDTH{1'b0}};
                else if (~(vec_rd_ctr == NO_OF_CLUSTERS)) 
                    data_mem_rdaddr <= data_mem_rdaddr + 1'b1;
            end
            
            if (cur_state == CLUSTER_COMP) begin                 
                if (mem_rd_level0 && ~data_mem_rden_mask) // the sequence will be 0,1,0 during level 0   
                    data_mem_rdaddr <= {data_mem_rdaddr[DIM_WIDTH-1:1],~data_mem_rdaddr[0]};                
                else if (centr_ctr_last && vec_rd_ctr_last) begin
                    if (data_mem_rdaddr == {DIM_WIDTH{1'b0}})
                        data_mem_rdaddr <= data_mem_rdaddr + 2'b10;
                    else
                        data_mem_rdaddr <= data_mem_rdaddr + 1'b1;
                end
            end
            
            if ((cur_state == CENTROID_COMP) &&
                  send_centr_comp_inp && vec_rd_ctr_last)
                data_mem_rdaddr <= data_mem_rdaddr + 1'b1;                    
        end   
    end    
    
    // memory_read_level0 Indicator
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            mem_rd_level0 <= 1'b0;
        else begin
            if (start_cluster_comp || start_conv_chk)
                mem_rd_level0 <= 1'b1;
            else begin
                if ((cur_state == CLUSTER_COMP) &&
                    centr_ctr_last_r && vec_rd_ctr_last_r)
                    mem_rd_level0 <= 1'b0;
                
                if ((cur_state == CONV_CHK) && centr_ctr_last)
                    mem_rd_level0 <= 1'b0;
            end
        end
    end        
    
    wire mem_rd_level0_complete;
    assign mem_rd_level0_complete = mem_rd_level0 && centr_ctr_last_r && vec_rd_ctr_last_r;
             
    // memory output register
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            data_mem_rdata_r <= {DATA_WIDTH{1'b0}};
        else if ((cur_state == CLUSTER_COMP) &&
                    data_mem_rdata_vld && ~data_mem_rdata_vld_r)
            data_mem_rdata_r <= data_mem_rdata;
    end        

    // memory output_vld register
    always @(posedge clk or negedge nreset) begin
        if (~nreset) 
            data_mem_rdata_vld_r <= 1'b0;
        else
            data_mem_rdata_vld_r <= data_mem_rdata_vld;
    end
    
    // Centroid register - registers one of the two outputs from centroid memories.
    // This is used only during level 0 of memory read. The value registered depends 
    // upon which of the two memory outputs corresponds to component 0.
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            centroid_r <= {DATA_WIDTH{1'b0}};
            centroid_old_r <= {DATA_WIDTH{1'b0}};
        end
        
        else begin  
            if (~centroid_r_wrmux_sel) begin
                centroid_r <= centroid_rdata0_in;
                centroid_old_r <= centroid_old_rdata0_in;
            end
            
            else if ((cur_state == CLUSTER_COMP) ||
                        (cur_state == CONV_CHK)) begin
                centroid_r <= centroid_rdata1_in;
                centroid_old_r <= centroid_old_rdata1_in;
            end
        end
    end
    
    // The select signal to control which value will be stored in the aforementioned register.
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            centroid_r_wrmux_sel <= 1'b0;
        else begin
            if (temp_mem_rdata_vld)
                centroid_r_wrmux_sel <= centroid_rdata_vld[0];
            else begin       
                if ((centroid_rdata_vld_r == 2'b11) && 
                     !(centroid_rdata_vld == 2'b11))
                    centroid_r_wrmux_sel <= 1'b0;         
                else if ((|centroid_rdata_vld &&
                           |centroid_rdata_vld_r) ||
                           ((centroid_rdata_vld_r == 2'b00) &&
                            (centroid_rdata_vld == 2'b01)))
                    centroid_r_wrmux_sel <= ~centroid_r_wrmux_sel;
            end            
        end
    end        
       
    //--------------------------------------------------------------------------------//
    // Temporary memory write 
    assign temp_mem_wraddr_last = (temp_mem_wraddr == NO_OF_CLUSTERS*NO_OF_PTS-1'b1);
    
    always @(posedge clk or negedge nreset) begin   
        if (~nreset) begin
            temp_mem_wren <= 1'b0;
            temp_mem_wrdata <= {DATA_WIDTH{1'b0}};
            temp_mem_wraddr <= {DIM_WIDTH{1'b0}};
        end
        
        else if (cur_state == CLUSTER_COMP) begin
            if (cordic_vec_opvld && ~cordic_vec_level_last) begin       
                temp_mem_wren <= 1'b1;
                temp_mem_wrdata <= cordic_vec_xout;
            end
            
            else
                temp_mem_wren <= 1'b0;
                
            // Temp mem write address
            if (temp_mem_wraddr_last)
                temp_mem_wraddr <= {DIM_WIDTH{1'b0}}; 
            else if (cordic_vec_opvld_r)
                temp_mem_wraddr <= temp_mem_wraddr + 1'b1;
        end
    end                  
    
    // Temporary memory Read enable
    always @(posedge clk or negedge nreset) begin   
        if (~nreset)
            temp_mem_rden <= 1'b0;
        else begin
            if (mem_rd_level0_complete)
                temp_mem_rden <= 1'b1;
            else if ((cur_state == CLUSTER_COMP) &&
                        centr_ctr_last && vec_rd_ctr_last && data_mem_rdaddr_last)
                temp_mem_rden <= 1'b0;
        end
    end
    
    // Temporary Memory Read Address
    assign temp_mem_rdaddr_last = (temp_mem_rdaddr == NO_OF_CLUSTERS*NO_OF_PTS-1'b1);
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            temp_mem_rdaddr <= {DIM_WIDTH{1'b0}};
        else begin
            if (temp_mem_rdaddr_last)
                temp_mem_rdaddr <= {DIM_WIDTH{1'b0}};
            else if (temp_mem_rden)
                temp_mem_rdaddr <= temp_mem_rdaddr + 1'b1;
        end
    end        
                
    /////////////////////////////////////////////////////////////////////////
    //--------------------Centroid Memory----------------------//
    /////////////////////////////////////////////////////////////////////////
    
    assign start_init_centroid = (cur_state == INPUTS) && (next_state == INIT_CENTROID);
    
    //----------------Current Centroid Read-----------------//
    
    // Centroid memory read enable
    // Centroid memory read enable is a shift register, with each
    // bit corresponding to one memory. The following load signal
    // indicates when to load the register with the initial value.
    wire load_centr_rden;

    assign load_centr_rden = start_cluster_comp || start_conv_chk || 
                                            ((cur_state == CONV_CHK) && 
                                            conv_chk_ctr_last && ~centroid_rdaddr0_last) || 
                                            ((cur_state == CLUSTER_COMP) && 
                                            ((~mem_rd_level0 && centr_ctr_last) ||
                                            (mem_rd_level0 && centr_ctr_last_r))) || 
                                            (centroid_comp_opvld && ~centroid_comp_opvld_r[1]);
        
    always @(posedge clk or negedge nreset) begin
        if (~nreset)       
            centroid_rden <= {NO_OF_CLUSTERS{1'b0}};
        else begin
            if (load_centr_rden)                
                centroid_rden <= {{NO_OF_CLUSTERS-1{1'b0}},1'b1};
            
            else if (mem_rd_level0) begin
                if (centroid_rden[0] && ~centroid_rden[1])
                    centroid_rden <= {centroid_rden[NO_OF_CLUSTERS-2:0],1'b1};
                else if ((cur_state == CLUSTER_COMP) ||
                        (cur_state == CONV_CHK))
                        centroid_rden <= {centroid_rden[NO_OF_CLUSTERS-2:0],1'b0};
            end
            
            else if ((cur_state == CLUSTER_COMP) || 
                        (centroid_comp_opvld_r[1]) ||
                        (cur_state == CONV_CHK))                
                centroid_rden <= {centroid_rden[NO_OF_CLUSTERS-2:0],1'b0};
        end
    end
    
    // Centroid old rden - Same as centroid rden, but used only during convergence check
    assign centroid_old_rden = (start_conv_chk || (cur_state == CONV_CHK)) ?
                                                centroid_rden : {NO_OF_CLUSTERS{1'b0}};          
    
    // Centroid Memory read address    
    // There are 2 addresses. This is because, during the memory read process for 
    // CVM level0 inputs, both x and y inputs to CVM are given as first two components
    // of the corresponding centroid. Since all the components of a centroid are stored
    // in the same memory, they should be read one at a time. This means that to give
    // x and y inputs to CVM level0, two cycles are required for each pair of x and y inputs.
    // To avoid this, while component 1 of one centroid is read, component 0 of the next 
    // centroid is read at the same time. These two addresses are used only during level
    // 0 of CVM. When rdaddr0 takes 1, rdaddr1 takes 0, and vice versa. From level 1 
    // onwards, one address is enough since the y-input of CVM is given from its x-output 
    // itself. The centroid_rdaddr1_vld signal indicates when the second read address 
    // (i.e. centroid_rdaddr1) is valid. The memory top wrapper takes care of this.  
    
    assign centroid_rdaddr1_vld = mem_rd_level0;
    assign centroid_rdaddr = {centroid_rdaddr1,centroid_rdaddr0};
    assign centroid_rdaddr0_last = (centroid_rdaddr0 == DIM-1'b1);
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin 
            centroid_rdaddr0 <= {DIM_WIDTH{1'b0}};
            centroid_rdaddr1 <= {DIM_WIDTH{1'b0}};
        end
        
        else begin
            if (cur_state == CLUSTER_COMP) begin
                if (mem_rd_level0_complete ||
                    (~mem_rd_level0 && centr_ctr_last && vec_rd_ctr_last))
                    centroid_rdaddr0 <= centroid_rdaddr0 + 1'b1;                    
                else if (mem_rd_level0) begin
                    centroid_rdaddr0 <= {centroid_rdaddr0[DIM_WIDTH-1:1],~centroid_rdaddr0[0]};    
                    centroid_rdaddr1 <= centroid_rdaddr0;
                end
            end
            
            if ((cur_state == CENTROID_COMP) &&
                ~centroid_comp_opvld && centroid_comp_opvld_r[1]) begin
                if (centroid_rdaddr0_last)
                    centroid_rdaddr0 <= {DIM_WIDTH{1'b0}};
                else
                    centroid_rdaddr0 <= centroid_rdaddr0 + 1'b1;
            end
            
            if (cur_state == CONV_CHK) begin
                if (conv_chk_ctr_last)
                    centroid_rdaddr0 <= centroid_rdaddr0 + 1'b1;
                else if (mem_rd_level0) begin
                    centroid_rdaddr0 <= {centroid_rdaddr0[DIM_WIDTH-1:1],~centroid_rdaddr0[0]};    
                    centroid_rdaddr1 <= centroid_rdaddr0;
                end
           end                             
        end        
    end    
    
    //----------------Current Centroid Write-----------------//
    assign init_centroid_complete = (cur_state == INIT_CENTROID) &&
                                centroid_wren[NO_OF_CLUSTERS-1] && centroid_wraddr_last;
                                
    assign centroid_wraddr_last = (centroid_wraddr == DIM-1'b1);            

    // Write Enable
    wire load_centr_wren;
    assign load_centr_wren = ((cur_state == INIT_CENTROID) && data_mem_rdata_vld && ~data_mem_rdata_vld_r) ||
                                              (centroid_comp_opvld_r[1] && ~centroid_comp_opvld_r[0]);
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            centroid_wren <= {NO_OF_CLUSTERS{1'b0}};
        else begin
            if (load_centr_wren)
                centroid_wren <= {{NO_OF_CLUSTERS-1{1'b0}},1'b1};
            else if (centroid_comp_opvld_r[1] || 
                      ((cur_state == INIT_CENTROID) && centroid_wraddr_last))
                centroid_wren <= (centroid_wren << 1);
            else if (init_centroid_complete || 
                       ((cur_state == CENTROID_COMP) && ~centroid_comp_opvld_r[1]))
                centroid_wren <= {NO_OF_CLUSTERS{1'b0}};
        end
    end        

    // Write Data
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            centroid_wrdata <= {DATA_WIDTH{1'b0}};
        else begin
            if (cur_state == INIT_CENTROID)                
                centroid_wrdata <= data_mem_rdata;            
            
            if (centroid_comp_opvld_r[1])
                centroid_wrdata <= centroid_comp_out_r;
        end
    end            

    // Write Address
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            centroid_wraddr <= {DIM_WIDTH{1'b0}};
        else if (((cur_state == INIT_CENTROID) && data_mem_rdata_vld_r) ||
                   (~centroid_comp_opvld_r[1] && centroid_comp_opvld_r[0])) begin      
            if (centroid_wraddr_last)
                centroid_wraddr <= {DIM_WIDTH{1'b0}};            
            else 
                centroid_wraddr <= centroid_wraddr + 1'b1;
        end
    end                                     
        
    // Writing the current centroid values to old Centroid Memory
    assign centroid_old_wraddr_last = (centroid_old_wraddr == DIM-1'b1);            

    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            centroid_old_wren <= {NO_OF_CLUSTERS{1'b0}};
            centroid_old_wrdata <= {DATA_WIDTH{1'b0}};
            centroid_old_wraddr <= {DIM_WIDTH{1'b0}};
        end
        
        else if (cur_state == CENTROID_COMP) begin
            if (|centroid_rdata_vld) begin
                if (centroid_rdata_vld_r == 2'b00)
                    centroid_old_wren <= {{NO_OF_CLUSTERS-1{1'b0}},1'b1};
                else
                    centroid_old_wren <= {centroid_old_wren[NO_OF_CLUSTERS-2:0],1'b0};
            end      
            
            else
                centroid_old_wren <= {NO_OF_CLUSTERS{1'b0}};      
            
            if (centroid_rdata_vld[0])
                centroid_old_wrdata <= centroid_rdata0_in;
            else if (centroid_rdata_vld[1])
                centroid_old_wrdata <= centroid_rdata1_in;
                
            if (~|centroid_rdata_vld && |centroid_rdata_vld_r) begin
                if (centroid_old_wraddr_last)
                    centroid_old_wraddr <= {DIM_WIDTH{1'b0}};
                else
                    centroid_old_wraddr <= centroid_old_wraddr + 1'b1;
            end
        end
    end                                     

    // Register the Centroid memory read_data valid signal.
    always @(posedge clk or negedge nreset) begin
        if (~nreset) 
            centroid_rdata_vld_r <= 2'b00;
        else
            centroid_rdata_vld_r <= centroid_rdata_vld;
    end

    //------------------------------------------------------------------------------------------------//
    // Centroid read counter - keeps track of which centroid value is used for CVM inputs.
    assign centr_ctr_last = (centr_ctr == NO_OF_CLUSTERS-1'b1);
    assign centr_ctr_zero = (centr_ctr == {NO_OF_CLUSTERS_WIDTH{1'b0}});
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            centr_ctr_last_r <= 1'b0;
            vec_rd_ctr_last_r <= 1'b0;
        end
        
        else begin
            centr_ctr_last_r <= centr_ctr_last;
            vec_rd_ctr_last_r <= vec_rd_ctr_last;
        end
    end
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) 
            centr_ctr <= {NO_OF_CLUSTERS_WIDTH{1'b0}};
        else begin
            if (centr_ctr_last)
                centr_ctr <= {NO_OF_CLUSTERS_WIDTH{1'b0}};
            else if (((cur_state == CLUSTER_COMP) && 
                       ~(cvm_inp_complete || (mem_rd_level0 && centr_ctr_last_r))) ||
                       ((cur_state == CONV_CHK) && mem_rd_level0))
                centr_ctr <= centr_ctr + 1'b1;
        end
    end
                     
    // Counter to indicate which vector/data point is being read.    
    assign vec_rd_ctr_last = (vec_rd_ctr == NO_OF_PTS[NO_OF_PTS_WIDTH-1:0]-1'b1);

    always @(posedge clk or negedge nreset) begin
        if (~nreset) 
            vec_rd_ctr <= {NO_OF_PTS_WIDTH{1'b0}};        
        else begin
            if (cur_state == INIT_CENTROID) begin
                if (init_centroid_complete)
                    vec_rd_ctr <= {NO_OF_PTS_WIDTH{1'b0}};
                else if (data_mem_rdaddr_last)
                    vec_rd_ctr <= vec_rd_ctr + 1'b1;
            end
                 
            if ((cur_state == CLUSTER_COMP) &&
                ((mem_rd_level0 && centr_ctr_last) || 
                  (~mem_rd_level0 && centr_ctr_last_r))) begin
                if ( vec_rd_ctr_last) 
                    vec_rd_ctr <= {NO_OF_PTS_WIDTH{1'b0}};
                else
                    vec_rd_ctr <= vec_rd_ctr + 1'b1;    
            end
            
            if (cur_state == CENTROID_COMP) begin
                if (vec_rd_ctr_last)
                    vec_rd_ctr <= {NO_OF_PTS_WIDTH{1'b0}};
                else if (~data_mem_rden_mask && send_centr_comp_inp)
                    vec_rd_ctr <= vec_rd_ctr + 1'b1;                                            
            end    
            
            if (cur_state == OUTPUTS) begin
                if (vec_rd_ctr_last)
                    vec_rd_ctr <= {NO_OF_PTS_WIDTH{1'b0}};
                else
                    vec_rd_ctr <= vec_rd_ctr + 1'b1;
            end
        end                
    end

    ////////////////////////////////////////////////////////////////////////////////////
    //------------------------Cluster Computation------------------------// 
    ////////////////////////////////////////////////////////////////////////////////////
    
    assign start_cluster_comp = ((cur_state == INIT_CENTROID) || 
                                                   (cur_state == CONV_CHK) || 
                                                   (cur_state == CENTROID_COMP)) && 
                                                   (next_state == CLUSTER_COMP);

    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            cluster_comp_data_vld <= 1'b0;
            cluster_comp_data_in <= {DATA_WIDTH{1'b0}};
        end
                
        else begin
            if ((cur_state == CLUSTER_COMP) &&
                cordic_vec_level_last && cordic_vec_opvld) begin
                cluster_comp_data_vld <= 1'b1;
                cluster_comp_data_in <= cordic_vec_xout;
            end
            
            else
                cluster_comp_data_vld <= 1'b0;
        end
    end                                
    
    // cvm_complete - signal indicating that the inputs to CVM during
    // the Cluster Computation stage have all been given.
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            cvm_inp_complete <= 1'b0;
        else if (cur_state == CLUSTER_COMP) begin
            if (centr_ctr_last && vec_rd_ctr_last && data_mem_rdaddr_last)
                cvm_inp_complete <= 1'b1;
            else if (cluster_comp_complete)
                cvm_inp_complete <= 1'b0;
        end
    end
            
    // Register file storing the assigned cluster of each point.
    reg [NO_OF_CLUSTERS_WIDTH-1:0] cluster_no [NO_OF_PTS-1:0];
    integer i;
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) 
            for (i=0;i<NO_OF_PTS;i=i+1) 
                cluster_no[i] <= {NO_OF_CLUSTERS_WIDTH{1'b0}};
        
        else begin
            if (cluster_comp_opvld)
                cluster_no[NO_OF_PTS-1] <= cluster_comp_out;
            else if (data_mem_rdata_vld && 
                       (cur_state == CENTROID_COMP))
                cluster_no[NO_OF_PTS-1] <= cluster_no[0];
                          
            if (cluster_comp_opvld || 
               ((cur_state == CENTROID_COMP) && data_mem_rdata_vld) ||
               (cur_state == OUTPUTS))
                for (i=0;i<NO_OF_PTS-1;i=i+1) 
                    cluster_no[i] <= cluster_no[i+1];
        end
    end
    
    // Cluster complete indicator
    assign cluster_comp_complete = (~cordic_vec_opvld && cluster_comp_opvld);
    
    /////////////////////////////////////////////////////////////////////////////////////////
    //----------------------Centroid Computation----------------------------//    
    /////////////////////////////////////////////////////////////////////////////////////////
    
    assign start_centroid_comp = (cur_state == CLUSTER_COMP) && 
                                               (next_state == CENTROID_COMP);
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) 
            send_centr_comp_inp <= 1'b0;
        else begin
            if (start_centroid_comp)
                send_centr_comp_inp <= 1'b1;
            else if ((cur_state == CENTROID_COMP) &&
                        data_mem_rdaddr_last && vec_rd_ctr_last)
                send_centr_comp_inp <= 1'b0;
        end
    end
         
    // Centroid computation inputs
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            centroid_comp_data_vld_in <= 1'b0;
        else
            centroid_comp_data_vld_in <= data_mem_rdata_vld &&
                                                  (cur_state == CENTROID_COMP);
    end                
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            centroid_comp_data_in <= {DATA_WIDTH{1'b0}};
            centroid_comp_cluster_no_in <= {NO_OF_CLUSTERS_WIDTH{1'b0}};
        end
        
        else if (data_mem_rdata_vld &&
                   (cur_state == CENTROID_COMP)) begin
            centroid_comp_data_in <= data_mem_rdata;
            centroid_comp_cluster_no_in <= cluster_no[0];
        end
    end                

    // Register the Centroid Computation outputs
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            centroid_comp_opvld_r <= 2'b00;
        else
            centroid_comp_opvld_r <= {centroid_comp_opvld,centroid_comp_opvld_r[1]};
    end

    always @(posedge clk or negedge nreset) begin
        if (~nreset) 
            centroid_comp_out_r <= {DATA_WIDTH{1'b0}};
        else if (centroid_comp_opvld)
            centroid_comp_out_r <= centroid_comp_out;
    end    

    // Signal indicating the end of Centroid Computation
    assign centroid_comp_complete = ~|centroid_rdata_vld && 
                                                             |centroid_rdata_vld_r && 
                                                             centroid_old_wraddr_last;
        
    //////////////////////////////////////////////////////////////////////////////////////////////
    //--------------------------Convergence Check---------------------------------//
    //////////////////////////////////////////////////////////////////////////////////////////////
    
  
    
    assign start_conv_chk = (cur_state == CENTROID_COMP) &&
                                           (next_state == CONV_CHK);
    
  //  localparam CONV_CHK_CTR_WIDTH = clogb2(CORDIC_LATENCY-1);
    
    // The following counter is used to synchronize memory read so
    // that centroid values are available when CVM output is available.
    assign conv_chk_ctr_last = (conv_chk_ctr == CORDIC_LATENCY);
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            incr_conv_chk_ctr <= 1'b0;
            conv_chk_ctr <= {CONV_CHK_CTR_WIDTH{1'b0}};
        end
        
        else begin
            if (cur_state == CONV_CHK) begin
                if (conv_chk_ctr_last)
                    incr_conv_chk_ctr <= 1'b0;
                else if ((mem_rd_level0 && (&centroid_rden[1:0]) ||
                            (~mem_rd_level0 && centroid_rden[0])));
                    incr_conv_chk_ctr <= 1'b1;
            
                if (conv_chk_ctr_last)
                    conv_chk_ctr <= {CONV_CHK_CTR_WIDTH{1'b0}};
                else if (incr_conv_chk_ctr)
                    conv_chk_ctr <= conv_chk_ctr + 1'b1;
            end
            
            else 
                incr_conv_chk_ctr <= 1'b0;
        end
    end
    
    // Checking for convergence    
    reg cmp;
    reg cmp_vld;        // cmp value is valid/ready.
    reg cmp_vld_r;     // Just to delay the above signal to detect its falling edge
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            cmp <= 1'b0;        
        else begin
            if ((cur_state == CONV_CHK) &&
                cordic_vec_level_last && cordic_vec_opvld) begin
                if (cordic_vec_xout[DATA_WIDTH-1])
                    cmp <= (-cordic_vec_xout < CONV_THRESH);
                else
                    cmp <= (cordic_vec_xout <= CONV_THRESH);
            end        
            
            else
                cmp <= 1'b0;                
        end
    end
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            cmp_vld <= 1'b0;
            cmp_vld_r <= 1'b0;            
        end
        
        else begin
            cmp_vld <= (cur_state == CONV_CHK) &&
                        cordic_vec_level_last && cordic_vec_opvld;
            cmp_vld_r <= cmp_vld;
        end
    end

    reg conv_chk_result;        // HIGH if all the centroids have converged.
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            conv_chk_result <= 1'b0;
        else begin
            if (start_conv_chk)
                conv_chk_result <= 1'b1;
            if (cmp_vld)
                conv_chk_result <= conv_chk_result && cmp;
            if (conv_rchd || conv_not_rchd)
                conv_chk_result <= 1'b0;
        end
    end
        
    assign conv_chk_complete = cmp_vld_r && ~cmp_vld;
    assign conv_rchd = conv_chk_complete && conv_chk_result;
    assign conv_not_rchd = conv_chk_complete && ~conv_chk_result;
        

    /////////////////////////////////////////////////////////////////////////////////////////////   
    //--------------------------CORDIC Vectoring Mode---------------------------//
    /////////////////////////////////////////////////////////////////////////////////////////////
    
    // CVM enable
    always @(posedge clk or negedge nreset) begin
        if (~nreset) 
            cordic_vec_en <= 1'b0;
        else begin 
            if (cur_state == CLUSTER_COMP) begin
                if (temp_mem_rdata_vld) 
                    cordic_vec_en <= 1'b1;
                else if (|centroid_rdata_vld_r ) begin
                    if ((~&centroid_rdata_vld) && 
                        (~&centroid_rdata_vld_r))
                        cordic_vec_en <= 1'b0;
                                            
                    else if (|centroid_rdata_vld)         // 2'b11
                        cordic_vec_en <= 1'b1;
                end                    
            end
                
            if (cur_state == CONV_CHK)
                cordic_vec_en <= (cordic_vec_opvld && ~cordic_vec_level_last) || 
                                             (&centroid_rdata_vld || 
                                             (&centroid_rdata_vld_r && (|centroid_rdata_vld)));
        end
    end
    
    // CVM x and y inputs
    
    // The following function is basically a mux. It is used to select one among the
    // 2 rdata outputs from centroid (both current and old) memories. This function 
    // is used mainly because the selection between the two rdata values happens 
    // multiple times, and using a function makes it more readable and concise.    
    function signed [DATA_WIDTH-1:0] mem_inp_sel;
        input signed [DATA_WIDTH-1:0] in1;
        input signed [DATA_WIDTH-1:0] in2;
        input signed [DATA_WIDTH-1:0] in_sel;
            
        mem_inp_sel = in_sel ? in1 : in2;
    endfunction
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            cordic_vec_xin <= {DATA_WIDTH{1'b0}};
            cordic_vec_yin <= {DATA_WIDTH{1'b0}};
        end
        
        else begin
            if (cur_state == CLUSTER_COMP) begin
                // x-input
                if (temp_mem_rdata_vld)                 //(&centroid_rdata_vld)
                    cordic_vec_xin <= data_mem_rdata - 
                            mem_inp_sel(centroid_rdata0_in, centroid_rdata1_in, centroid_rdata_vld[0]);
                else
                    cordic_vec_xin <= data_mem_rdata_r - centroid_r;


                // y-input
                if (temp_mem_rdata_vld)
                    cordic_vec_yin <= temp_mem_rdata;
                else                //if (&centroid_rdata_vld)
                    cordic_vec_yin <= data_mem_rdata - 
                                mem_inp_sel(centroid_rdata0_in, centroid_rdata1_in, centroid_r_wrmux_sel);                
            end
            
            if (cur_state == CONV_CHK) begin
                // x-input
                if (cordic_vec_opvld)
                    cordic_vec_xin <= mem_inp_sel(centroid_rdata0_in, centroid_rdata1_in, centroid_rdata_vld[0]) -
                                mem_inp_sel(centroid_old_rdata0_in, centroid_old_rdata1_in, centroid_rdata_vld[0]);                                
                else
                    cordic_vec_xin <= centroid_r - centroid_old_r;
                    
                     
                // y-input
                if (cordic_vec_opvld)
                    cordic_vec_yin <= cordic_vec_xout;
                else
                    cordic_vec_yin <= mem_inp_sel(centroid_rdata0_in, centroid_rdata1_in, centroid_rdata_vld[0]) -
                            mem_inp_sel(centroid_old_rdata0_in, centroid_old_rdata1_in, centroid_rdata_vld[0]);                                
            end
        end
    end        
    
    // Register the CVM output valid
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            cordic_vec_opvld_r <= 1'b0;
        else
            cordic_vec_opvld_r <= cordic_vec_opvld;
    end
        
    // CVM output ctr - Used to indicate when CVM level counter should increment.
    localparam CVM_OP_CTR_SIZE = clogb2(NO_OF_PTS*NO_OF_CLUSTERS-1);
    reg [CVM_OP_CTR_SIZE-1:0] cordic_vec_op_ctr;
    wire cordic_vec_op_ctr_last;
    
    assign cordic_vec_op_ctr_last = (cordic_vec_op_ctr == NO_OF_PTS*NO_OF_CLUSTERS-1'b1);
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            cordic_vec_op_ctr <= {CVM_OP_CTR_SIZE{1'b0}};
        else if ((cur_state == CLUSTER_COMP) && cordic_vec_opvld) begin
            if (cordic_vec_op_ctr_last)
                cordic_vec_op_ctr <= {CVM_OP_CTR_SIZE{1'b0}};
            else
                cordic_vec_op_ctr <= cordic_vec_op_ctr + 1'b1;
        end         
    end
        
    // CVM level counter
    assign cordic_vec_level_last = (cordic_vec_level_ctr == DIM[DIM_WIDTH-1:0]-2'b10);
        
    assign incr_vec_level_ctr = ((cur_state == CLUSTER_COMP) && cordic_vec_op_ctr_last) ||
                             ((cur_state == CONV_CHK) && cordic_vec_opvld_r && ~cordic_vec_opvld);        
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset)
            cordic_vec_level_ctr <= {DIM_WIDTH{1'b0}};
        else if (incr_vec_level_ctr) begin
            if (cordic_vec_level_last)
                cordic_vec_level_ctr <= {DIM_WIDTH{1'b0}};            
            else 
                cordic_vec_level_ctr <= cordic_vec_level_ctr + 1'b1;
        end
    end            
   
    /////////////////////////////////////////////////////////////////////
    //-------------------------Outputs---------------------------//
    /////////////////////////////////////////////////////////////////////
    
    assign output_complete = (cur_state == OUTPUTS) && (vec_rd_ctr_last);
    
    always @(posedge clk or negedge nreset) begin
        if (~nreset) begin
            output_vld <= 1'b0;
            cluster_no_out <= {NO_OF_CLUSTERS_WIDTH{1'b0}};
        end
        
        else begin
            if (cur_state == OUTPUTS) begin
                output_vld <= 1'b1;
                cluster_no_out <= cluster_no[0];
            end
            
            else
                output_vld <= 1'b0;
        end
    end
                    
endmodule
