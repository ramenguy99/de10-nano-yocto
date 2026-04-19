module control_io (
  input logic clk,
  input logic reset,

  // Avalon MM - Slave
  //
  // Control IO
  input logic avs_s0_write,
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
  output logic interrupt_sender_irq
);

always_comb begin
  interrupt_sender_irq = 1'b0;
  avm_m0_write = 1'b1;
end

always_ff @(posedge clk ) begin
  avm_m0_read = ~avm_m0_read;
  // avm_m0_read = ~avm_m0_read;

  if (reset) begin
      avm_m0_read = 1'b0;
  end
end

endmodule