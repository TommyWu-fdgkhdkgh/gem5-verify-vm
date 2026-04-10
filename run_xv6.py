import os
import m5
from m5.objects import Root
from gem5.components.boards.riscv_board import RiscvBoard
from gem5.components.memory.single_channel import SingleChannelDDR3_1600
from gem5.components.processors.simple_processor import SimpleProcessor
from gem5.components.processors.cpu_types import CPUTypes
from gem5.components.cachehierarchies.classic.private_l1_cache_hierarchy import PrivateL1CacheHierarchy
from gem5.resources.resource import CustomResource, CustomDiskImageResource, BinaryResource, DiskImageResource
from gem5.simulate.simulator import Simulator
from gem5.utils.requires import requires
from gem5.isas import ISA

requires(isa_required=ISA.RISCV)

# 1. Instantiate the cache hierarchy
cache_hierarchy = PrivateL1CacheHierarchy(
    l1d_size="16KiB",
    l1i_size="16KiB"
)

# 2. Instantiate the memory system (256MB is needed for gem5's DTB placement)
memory = SingleChannelDDR3_1600("256MiB")

# 3. Instantiate the processor (Simple timing CPU, single core)
'''
processor = SimpleProcessor(
    cpu_type=CPUTypes.MINOR,
    isa=ISA.RISCV,
    num_cores=3
)
'''
processor = SimpleProcessor(
    cpu_type=CPUTypes.ATOMIC,
    isa=ISA.RISCV,
    num_cores=3
)

# 4. Instantiate the board
board = RiscvBoard(
    clk_freq="1GHz",
    processor=processor,
    memory=memory,
    cache_hierarchy=cache_hierarchy
)

# 5. Set the workload
# We pass the xv6 kernel and the filesystem image.
# We explicitly set bootloader to empty so the board loads the kernel at 0x80000000.
board.set_kernel_disk_workload(
    kernel=BinaryResource("xv6-riscv/kernel/kernel"),
    disk_image=DiskImageResource("xv6-riscv/fs.img")
)

# 6. Instantiate the Simulator
simulator = Simulator(board=board)

print(f"entry_point: {hex(board.workload.entry_point)}, kernel_addr: {hex(board.workload.kernel_addr)}")
print("Beginning simulation!")
simulator.run()

print(f"Exiting @ tick {simulator.get_current_tick()} because {simulator.get_last_exit_event_cause()}")
