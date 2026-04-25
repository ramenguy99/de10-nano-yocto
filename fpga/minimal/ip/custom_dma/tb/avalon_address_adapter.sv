module avalon_address_adapter (
  input logic clk,
  input logic reset,

  // Avalon MM - Slave
  //
  // Control IO
  input logic avs_s0_write,
  input logic [5:0] avs_s0_address,
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

control_io control_io (
  .clk                   (clk),
  .reset                 (reset),
  .avs_s0_write          (avs_s0_write),
  .avs_s0_address        (avs_s0_address[5:2]),
  .avs_s0_writedata      (avs_s0_writedata),
  .avs_s0_read           (avs_s0_read),
  .avs_s0_readdata       (avs_s0_readdata),
  .avm_m0_read           (avm_m0_read),
  .avm_m0_write          (avm_m0_write),
  .avm_m0_writedata      (avm_m0_writedata),
  .avm_m0_address        (avm_m0_address),
  .avm_m0_readdata       (avm_m0_readdata),
  .avm_m0_readdatavalid  (avm_m0_readdatavalid),
  .avm_m0_byteenable     (avm_m0_byteenable),
  .avm_m0_waitrequest    (avm_m0_waitrequest),
  .avm_m0_burstcount     (avm_m0_burstcount),
  .interrupt_sender_irq  (interrupt_sender_irq),
  .out_data              (out_data)
);


endmodule