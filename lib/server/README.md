# Hardware

## Tentative API

### Motherboard

#### Action



#### Query

- get_resources(mobo_id) :: %{cpu: %{clock: x}, hdd: %{size: y, iops: z}}


### Component

#### Action

#### Query

- fetch(comp_id)

- fetch_spec(spec_id)

### Comments

- components are global (can be used by any mobo)
- mobos are specific per type of server
- they (mobo) define most custom behaviour
- components may receive server_type to further customize behaviour

o Mainframe

- main PC. must always be online. Must not be disassembled/taken offline

o Durability

- affects effective power for each resource (percentage multiplier *per component*)
- consumption based on TOP's processed info (updated on ProcessCompletedEvent)

o Orphaned components

- orphaned components must be linked to their entity
- effective power of the component must be persisted alongside it

