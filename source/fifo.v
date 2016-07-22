module fifo #(parameter depth_bits = 3, parameter data_width = 8)(
    input clk,
    input rst,
    input [data_width-1:0] data_i,
    input we,
    input [data_width-1:0] data_o,
    input re,
    output flag_empty,
    output flag_half_full,
    output flag_full
);

parameter fifo_depth = 1 << depth_bits;


// Internal registers
reg [data_width-1:0] fifo_memory [fifo_depth-1:0];
reg [depth_bits-1:0] write_pointer;
reg [depth_bits-1:0] read_pointer;
reg [depth_bits-1:0] fifo_level;
reg [data_width-1:0] data_o_buffer;

// Flag logic
assign flag_empty = (fifo_level == 0);
assign flag_half_full = fifo_level == (1 << (depth_bits-1)));
assign flag_full = (fifo_level == fifo_depth);

// Internal signals
wire write_through = (fifo_empty && we && re);
wire [data_width-1:0] memory_output = fifo_memory[read_pointer];

// Fifo level
always@(posedge clk)begin
    if(rst)
        fifo_level <= 0;
    else begin
        if(we && (!re) && (!fifo_full))
            fifo_level <= fifo_level + 1;
        else if((!we) && re && (!fifo_empty))
            fifo_level <= fifo_level - 1;
    end
end

// Write pointer
always@(posedge clk)begin
    if(rst)
        write_pointer <= 0;
    else if(we && (!write_through) && ((!flag_full) || (flag_full && re)))begin
        fifo_memory[write_pointer] <= data_i;
        write_pointer <= write_pointer + 1;
    end
end

//Read
always@(posedge clk)begin
    if(rst)
        read_pointer <= 0;
    else if(re && ((!flag_empty))
        read_pointer <= read_pointer + 1;
end

always@(posedge clk)begin
    if(write_through)
        data_o_buffer <= data_i;
    else
        data_o_buffer <= memory_output;
end

assign  data_o = data_o_buffer;

endmodule
