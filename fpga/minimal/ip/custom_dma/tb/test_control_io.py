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
async def my_first_test(dut):
    # Clock
    cocotb.start_soon(Clock(dut.clk, 1, unit="ns").start())

    # Reset
    await cycle_reset(dut)

    # Run some clocks
    CLOCKS = 6
    await Timer(CLOCKS, unit="ns")

    # cocotb.log.info("my_signal_1 is %s", dut.my_signal_1.value)
    assert dut.interrupt_sender_irq.value == 0
    assert dut.avm_m0_write.value == 1
    assert dut.avm_m0_read.value == CLOCKS % 2
