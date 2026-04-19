import cocotb
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotb.clock import Clock
from cocotb.handle import Immediate

async def cycle_reset(dut):
    dut.reset.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.reset.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await RisingEdge(dut.clk)

@cocotb.test()
async def custom_dma_test(dut):
    # Clock
    cocotb.start_soon(Clock(dut.clk, 1, unit="ns").start())

    TEST_VALUE = 0x1234
    READ_ADDRESS = 0xdeadbeef
    WRITE_ADDRESS = 0xcafebabe

    # Init
    dut.avm_m0_readdata.value = TEST_VALUE
    dut.avm_m0_readdatavalid.value = 0

    # Reset
    await cycle_reset(dut)

    dut.avm_m0_waitrequest.value = 1

    # Write read addr
    dut.avs_s0_address.value = 1
    dut.avs_s0_write.value = 1
    dut.avs_s0_writedata.value = READ_ADDRESS
    await RisingEdge(dut.clk)

    # Write write addr
    dut.avs_s0_address.value = 2
    dut.avs_s0_write.value = 1
    dut.avs_s0_writedata.value = WRITE_ADDRESS
    await RisingEdge(dut.clk)

    # Write trigger
    dut.avs_s0_address.value = 0
    dut.avs_s0_write.value = 1
    dut.avs_s0_writedata.value = 1
    await RisingEdge(dut.clk)

    # Reset write signals
    dut.avs_s0_address.value = 0
    dut.avs_s0_write.value = 0
    dut.avs_s0_writedata.value = 0

    # Simulate bus busy before taking in read
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.avm_m0_waitrequest.value = 0
    assert dut.avm_m0_address.value == READ_ADDRESS

    # Simulate read takes 2 cycles
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.avm_m0_readdatavalid.value = 1

    # Drain
    await Timer(10, unit="ns")

    assert dut.interrupt_sender_irq.value == 0
    assert dut.out_data.value == TEST_VALUE
