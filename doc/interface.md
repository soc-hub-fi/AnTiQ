# Another Timer Queue (AnTiQ) (µArch-07/25)

## Parametrization

The design is constrained primarily by the parameters:

- `Depth`, Default: 8
- `TimestampWidth` Default: 24

`Depth` is the maximal depth of the queue, i.e., number of supported entries.

`TimestampWidth` is the number of bits used to represent timestamps internally.

The default sizes are chosen deliberately to be able to pack both an index and a timestamp into a 32-bit register. The mapping will need to be revised to support larger timestamps generally.

## Operation

AnTiQ exposes three explicit operations to the programmer through a memory-mapped register interface: a relative `push`, an absolute `push`, and a `drop`.
The above operations map directly to the three write-only registers in the memory map.

The design performs `pop` implicitly when the top queue entry "expires", i.e., the timestamp value is greater than `mtime`.

## Register Mapping

Base address in current Atalanta integration: **32'h0004_0000**

| Base Offset | Name       | Access | 
|-------------|------------|--------|
| 0x0         | `status`   | `r/o`  |
| 0x4         | `last`     | `r/o`  |
| 0x8         | `push_rel` | `w/o`  |
| 0xC         | `push_abs` | `w/o`  |
| 0x10        | `drop`     | `w/o`  |


`status`:
| Field Offset | (Reserved) Width | Name   | Description |
|--------------|------------------|--------|-------------|
| 24           | 8                | `top`  | Queue index for top entry in priority queue. When evicting entries out of a full queue in favour of new ones, evictions should be done on any index other than this.*|
| 8            | 1                | `empty`| "Queue is empty" -flag. |
| 0            | 1                | `full` | "Queue is full" -flag. Inserting new entries in this state requires evicting existing entries.** |

*Ideally, the lowest priority entry would be evicted. However, computing the lowest priority entry would require a second arbitration tree parallel to the top priority arbitration. This maybe future work if deemed useful, but the reasoning here is that "not-top priority" is a good enough eviction canditate generally.

**Currently, the design technically permits pushing into a full queue. However, this is considered undefined behavior and every push operation should be guarded with a check of `full`.

`last`:
| Field Offset | (Reserved) Width | Name   | Description |
|--------------|------------------|--------|-------------|
| 0            | `clog2(Depth)`   | `last` | Queue index of last pushed timestamp. This is needed for software bookeeping for cases when the entry may want to be dropped in the future. |

`push_rel`:
| Field Offset | (Reserved) Width | Name        | Description |
|--------------|------------------|-------------|-------------|
| 24           | `PayloadWidth`   | `payload`   | ID of interrupt to be dispatched. |
| 0            | 24               | `Timestamp` | The relative offset timestamp for the queue entry. |

`push_abs`:
| Field Offset | (Reserved) Width | Name | Description |
|--------------|------------------|------|-------------|
| 24           | `PayloadWidth`   | `payload` | ID of interrupt to be dispatched. |
| 0            | 24               | `Timestamp` | The absolute dispatch timestamp for the queue entry. |

`drop`:
| Field Offset | (Reserved) Width | Name   | Description |
|--------------|------------------|--------|-------------|
| 0            | `clog2(Depth)`   | `drop` | The queue index for the entry to be dropped. Generally sourced by polling `last` after inserting an entry. |





