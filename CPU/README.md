# CO2070 Lab 7 - Instruction Cache and Memory (group04)

This builds on the Lab 6 (data cache) design. The CPU, ALU, register file and
shift unit are **unchanged** from Lab 6 -- instruction fetch was already an
external memory-mapped access (`PC` out / `INSTRUCTION` in / `BUSYWAIT` in),
so no CPU datapath changes were required, only a new instruction-side memory
hierarchy and a combined stall signal.

## New / changed files

| File                    | What it is |
|--------------------------|------------|
| `icache.v`               | **New.** Direct-mapped, read-only instruction cache (128B cache, 16B blocks, 8 lines). |
| `instruction_memory.v`   | The module supplied with the Lab 7 handout (256 words / 1024 Bytes, 16-Byte block reads). Only change: the program is loaded with `$readmemb` from a `.mem` file instead of being fully hardcoded, so different test programs can be swapped in easily. |
| `cpu_tb.v`               | **New top-level testbench.** Wires `cpu` -> `icache` -> `instruction_memory`, and keeps `cpu` -> `dcache` -> `data_memory` from Lab 6. `BUSYWAIT` fed to the CPU is `ic_busywait \| dc_busywait`. |
| `cpu.v`, `dcache.v`, `data_memory.v`, `alu.v`, `reg_file.v`, `shift_unit.v` | Unchanged from the Lab 6 submission. |

## Address breakdown used by `icache.v`

The CPU's PC is used as a 10-bit word address (`address[1:0]` is always `00`
since instructions are word-aligned):

```
 9        7 6      4 3        0
+----------+---------+----------+
|   TAG    |  INDEX  |  OFFSET  |
+----------+---------+----------+
  (3 bits)   (3 bits)  (4 bits)
```

`offset[3:2]` selects which of the 4 words inside a 16-Byte block is being
requested. `{tag, index}` (6 bits) is exactly the block address the cache
uses to talk to `instruction_memory`.

Latencies match the handout: `#1` to extract the indexed valid/tag/data,
`#0.9` for tag comparison, `#1` to select the requested word (runs in
parallel with the tag comparison), and `#1` to write a freshly-fetched block
into the cache. Simulation confirms a full miss (address issued to CPU
un-stalled) costs ~81 CPU cycles, matching the handout's total.

## Test programs

Two assembly programs are included (both already assembled to `.machine`
and converted to a byte-ordered `.mem` file with `generate_memory_image.sh`):

1. **`icache_test.s` / `icache_test.mem`** (loaded by default in
   `instruction_memory.v`) -- an instruction-cache stress test:
   - Sequentially executes blocks 0, 1 and 2 (compulsory misses, then hits
     for every instruction after the first one in a block).
   - Jumps to word address 32 (block 8), which maps to the **same cache
     index as block 0** (direct-mapped conflict) -- this evicts block 0.
   - Jumps back to word address 0, forcing block 0 to be **re-fetched**
     (conflict miss), then repeats -- demonstrating classic direct-mapped
     cache thrashing between two blocks that alias to the same index.
2. **`sample_program.s` / `sample_program.mem`** -- a full functional test
   exercising every instruction in the ISA (`loadi`, `mov`, `add`, `sub`,
   `and`, `or`, `sll/srl/sra/ror`, `bne`, `beq`, `mult`, `j`), useful for
   checking overall CPU + cache correctness rather than cache-specific
   corner cases.

To load a different program, reassemble it and regenerate its `.mem` file:

```
gcc CO2070Assembler.c -o CO2070Assembler
./CO2070Assembler your_program.s
./generate_memory_image.sh your_program.s      # writes instr_mem.mem
mv instr_mem.mem your_program.mem
```

Then change the file name (and, if needed, the `$readmemb` byte range) in
`instruction_memory.v`.

## Running the simulation

```
iverilog -o icache_sim cpu_tb.v cpu.v icache.v instruction_memory.v dcache.v data_memory.v alu.v reg_file.v shift_unit.v
vvp icache_sim
```

This produces `cpu_wavedata.vcd`, and prints the final instruction-cache
state and register file to the console. Open the `.vcd` in GTKWave to
inspect the instruction-cache/CPU-control signals (`PC`, `INSTRUCTION`,
`ic_busywait`, `imem_read`, `imem_busywait`, `my_icache.state`, etc.) and
capture the timing-diagram screenshots required by the handout -- a GUI
waveform viewer isn't available in this environment, so that step still
needs to be done locally before zipping up `group04_lab7.zip`.
