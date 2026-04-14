import os
import m5
import argparse
from m5.objects import Root
from gem5.components.boards.riscv_board import RiscvBoard
from gem5.components.memory.single_channel import SingleChannelDDR3_1600
from gem5.components.processors.simple_processor import SimpleProcessor
from gem5.components.processors.cpu_types import CPUTypes
from gem5.components.cachehierarchies.classic.no_cache import NoCache
from gem5.components.cachehierarchies.classic.private_l1_cache_hierarchy import PrivateL1CacheHierarchy
from gem5.resources.resource import CustomResource, CustomDiskImageResource, KernelResource, BinaryResource, DiskImageResource
from gem5.simulate.simulator import Simulator
from gem5.utils.requires import requires
from gem5.isas import ISA

requires(isa_required=ISA.RISCV)

# -------------- add options -------------- #
parser = argparse.ArgumentParser()
parser.add_argument(
    '--cpu-type',
    action="store",
    dest='cpu_type',
    required=False,
    default="timing",
    choices=['atomic', 'timing', 'minor', 'o3'],
    help='The type of the CPU model',
)
parser.add_argument(
    '--num-cores',
    action="store",
    type=int,
    dest='num_cores',
    required=False,
    default=3,
    help='The number of cores',
)
parser.add_argument(
    '--kernel-type',
    action="store",
    dest='kernel_type',
    required=False,
    default="xv6-riscv",
    choices=['xv6-riscv', 'linux'],
    help='The type of the kernel',
)
parser.add_argument(
    '--vm-mode',
    action="store",
    dest='vm_mode',
    required=False,
    default="sv39",
    choices=['sv39', 'sv48', 'sv57'],
    help='The type of the virtual memory mode',
)

# ---------------------------- Parse Options --------------------------- #
args = parser.parse_args()

# 1. Instantiate the cache hierarchy
if args.cpu_type == "atomic":
    # it's for atomic
    cache_hierarchy = NoCache()
else:
    cache_hierarchy = PrivateL1CacheHierarchy(
        l1d_size="16KiB",
        l1i_size="16KiB"
    )

# 2. Instantiate the memory system (256MB is needed for gem5's DTB placement)
memory = SingleChannelDDR3_1600("256MiB")

# 3. Instantiate the processor (Simple timing CPU, single core)
print(f"num-cores : {args.num_cores}")
if args.cpu_type == "atomic":
    print("cpy_type : atomic")
    processor = SimpleProcessor(
        cpu_type=CPUTypes.ATOMIC, isa=ISA.RISCV, num_cores=args.num_cores
    )
elif args.cpu_type == "timing":
    print("cpy_type : timing")
    processor = SimpleProcessor(
        cpu_type=CPUTypes.TIMING, isa=ISA.RISCV, num_cores=args.num_cores
    )
    pass
elif args.cpu_type == "minor":
    print("cpy_type : minor")
    processor = SimpleProcessor(
        cpu_type=CPUTypes.MINOR, isa=ISA.RISCV, num_cores=args.num_cores
    )
elif args.cpu_type == "o3":
    print("cpy_type : o3")
    processor = SimpleProcessor(
        cpu_type=CPUTypes.O3, isa=ISA.RISCV, num_cores=args.num_cores
    )
else:
    assert False

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
if args.kernel_type == "xv6-riscv":
    kernel = BinaryResource("xv6-riscv/kernel/kernel")
    disk_image = DiskImageResource("xv6-riscv/fs.img")
    kernel_args=[]
elif args.kernel_type == "linux":
    kernel = KernelResource(local_path="./opensbi_gem5/build/platform/generic/firmware/fw_payload.elf")
    disk_image = DiskImageResource(local_path="./buildroot_gem5/output/images/rootfs.ext4")
    kernel_args=["console=ttyS0", "earlycon=uart8250,mmio,0x10000000", "root=/dev/vda", "rw"]

    if args.vm_mode == "sv39":
        kernel_args += ["no4lvl"]
    elif args.vm_mode == "sv48":
        kernel_args += ["no5lvl"]
    elif args.vm_mode == "sv57":
        pass
    else:
        assert False
else:
    assert False

board.set_kernel_disk_workload(
    kernel=kernel,
    disk_image=disk_image,
    kernel_args=kernel_args
)

# 6. Instantiate the Simulator
simulator = Simulator(board=board)

print(f"entry_point: {hex(board.workload.entry_point)}, kernel_addr: {hex(board.workload.kernel_addr)}")
print("Beginning simulation!")
simulator.run()

print(f"Exiting @ tick {simulator.get_current_tick()} because {simulator.get_last_exit_event_cause()}")
