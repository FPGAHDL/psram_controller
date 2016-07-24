
module psram_burst_controller #
(
    parameter address_width = 16,
    parameter data_width = 16,
    parameter psram_address_width = 23,
    parameter access_latency = 1,
    parameter burst_size = 31
)

(
    input rst_i,
    input clk_i,
    input [address_width-1:0] adr_i,
    input [data_width-1:0] dat_i,
    output [data_width-1:0] dat_o,
    input stb_i,
    input cyc_i,
    input we_i,
//    input ack_o,
//    input stall_o,
    output psram_clk,
    output [psram_address_width-1:0] psram_adr,
    output [data_width-1:0] psram_dat_o,
    output psram_we_n,
    output reg psram_ce_n,
    output reg psram_adv_n,
    output reg psram_oe_n
);

reg counter_en;
reg [8:0] counter;

always@(posedge clk_i)begin
    if(!counter_en)
        counter <= 0;
    else
        counter <= counter + 1;
end

localparam state_bits = 4;

reg [state_bits-1:0] state;
reg [state_bits-1:0] next_state;

localparam state_idle= 0;
localparam state_address_set = 1;
localparam state_access_wait = 2;
localparam state_xfer = 3;


reg load_address;
reg [address_width-1:0] address_reg;

// Address save
always@(posedge clk_i)begin
    if(rst_i)
        address_reg <= 0;
    else if(load_address)
        address_reg <= adr_i;
end

reg load_we;
reg we_reg;

// we save
always@(posedge clk_i)begin
    if(rst_i)
        we_reg <= 1;
    else if(load_we)
        we_reg <= we_i;
end

// Update state register
always@(posedge clk_i)begin
    if(rst_i)
        state <= state_idle;
    else
        state <= next_state;
end

wire wishbone_cyc_start =  cyc_i && stb_i;

// next state decoder
always@(*)begin
    next_state = state_idle;
    if(state == state_idle)begin
        if(wishbone_cyc_start)
           next_state = state_address_set;
        else
           next_state = state_idle;
    end
    else if(state == state_address_set)begin
       next_state = state_access_wait;
    end
    else if(state == state_access_wait)begin
        if(counter < access_latency)
            next_state = state_access_wait;
        else
            next_state = state_xfer;
    end
    else if(state == state_xfer)begin
        if(counter < burst_size)
            next_state = state_xfer;
        else
            next_state = state_idle;
    end
end


// Ouput decoder
always@(*)begin
    psram_ce_n = 1;
    psram_adv_n = 1;
    psram_oe_n = 1;

    load_we = 0;
    load_address = 0;
    counter_en = 0;

    if(state == state_idle)begin
        if(wishbone_cyc_start)begin
            load_we = 1;
            load_address = 1;
        end
    end
    else if(state == state_address_set)begin
        psram_ce_n = 0;
        psram_adv_n = 0;
    end
    else if(state == state_access_wait)begin
        psram_ce_n = 0;
        if(counter < access_latency)
            counter_en = 1;
        else
            psram_oe_n = we_reg;
    end
    else if(state == state_xfer)begin
        psram_ce_n = 0;
        if(counter < burst_size)begin
            counter_en = 1;
            psram_oe_n = we_reg;
        end
    end
end

assign psram_we_n = ~we_reg;
assign psram_adr = address_reg;
assign psram_dat_o = (state == state_xfer) ? counter : 16'hffff;
assign psram_clk = ~clk_i;

assign dat_o = 0;

endmodule
