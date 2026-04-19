module control_io (
  input logic clk,
  input logic reset,

  // Avalon MM - Slave
  //
  // Control IO
  input logic avs_s0_write,
  input logic [3:0] avs_s0_address,
  input logic [31:0] avs_s0_writedata,
  input logic avs_s0_read,
  output logic [31:0] avs_s0_readdata,

  // Avalon MM - Master
  //
  // Bidirectional ports i.e. read from and write to SDRAM.
  output  logic         avm_m0_read,
  output  logic         avm_m0_write,
  output  logic [255:0] avm_m0_writedata,
  output  logic [31:0]  avm_m0_address,
  input   logic [255:0] avm_m0_readdata,
  input   logic         avm_m0_readdatavalid,
  output  logic [31:0]  avm_m0_byteenable,
  input   logic         avm_m0_waitrequest,
  output  logic [10:0]  avm_m0_burstcount,

  // Interrupts
  output logic interrupt_sender_irq,

  // Debug output
  output logic [255:0] out_data
);

// Control IO
logic trigger;
logic [31:0] sdram_read_addr;
logic [31:0] sdram_write_addr;

always_ff @(posedge clk ) begin
  trigger <= 0;

  if (avs_s0_write)
  begin
    case (avs_s0_address)
      4'b0000: trigger <= avs_s0_writedata[0];
      4'b0001: sdram_read_addr <= avs_s0_writedata;
      4'b0010: sdram_write_addr <= avs_s0_writedata;
      default: begin end
    endcase
  end

  if (reset) trigger <= 0;
end


// State machine
localparam INIT = 2'd0;
localparam READ_START = 2'd1;
localparam READ_END = 2'd2;

logic [1:0] cur_state;
logic [1:0] next_state;


always_comb begin
  next_state = cur_state;
  case(cur_state)
    INIT: begin
      if (trigger) next_state = READ_START;
    end

    READ_START: begin
      if (avm_m0_waitrequest) next_state = READ_START; // Wait here.
      else next_state = READ_END;
    end

    READ_END: begin
      if (!avm_m0_readdatavalid) next_state = READ_END; // Wait here.
      else next_state = INIT;
    end

    default: begin
      next_state = INIT;
    end
  endcase
end

always_ff @(posedge clk ) begin
  if (reset) cur_state <= INIT;
  else cur_state <= next_state;
end

// Avalon master read
always_comb begin
  avm_m0_address = 32'd0;
  avm_m0_read = 1'b0;
  avm_m0_byteenable = 32'd0;
  avm_m0_burstcount = 11'd0;

  case(cur_state)

    READ_START: begin
      avm_m0_address = sdram_read_addr;
      avm_m0_read = 1'b1;
      avm_m0_byteenable = 32'h0000_000F; // Get 32 bits only.
      avm_m0_burstcount = 11'd1; // Get only 1 address value.
    end

    default: begin
    end
  endcase
end

always_ff @(posedge clk) begin
  if (reset) out_data <= 256'd0;
  else begin
    case (cur_state)
      READ_END: begin
        if (avm_m0_readdatavalid) begin
          out_data <= avm_m0_readdata;
        end
      end

      default: begin
      end
    endcase
  end
end

// Interrupts
always_ff @(posedge clk) begin
  if (reset) interrupt_sender_irq <= 1'b0;
end

endmodule