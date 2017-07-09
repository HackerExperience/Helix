# Style Guide [WIP]

## Alias naming

- When importing a Model, it's OK to use the module name as is.
- For all other services, add a qualifier sufix, like `Query` or `Action`
- Does not apply for `Repo` and other "special" modules.

Examples:

```elixir
alias HELL.PK
alias Helix.Server.Repo
alias Helix.Server.Model.Server
alias Helix.Hardware.Model.NetworkConnection
alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
alias Helix.Log.Action.Log, as: LogAction
```

Open questions:

- How to deal with really large sub modules, like process/TOP and Universe/NPC?
  - Sug: Add sub-module name as sufix. Eg: ServerResourcesTOP


Sug:

- Split Action into flow+action. Flow is a special type of action
