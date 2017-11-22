# Style Guide [WIP]

## Alias naming

- When importing a `Model`, it's OK to use the module name as is.
- For all other services, add a qualifier sufix, like `Query` or `Action`
- Does not apply for `Repo` and other "special" modules.

Examples:

```elixir
alias HELL.PK
alias Helix.Server.Model.Server
alias Helix.Server.Repo
alias Helix.Hardware.Model.NetworkConnection
alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
alias Helix.Log.Action.Log, as: LogAction
```

## Alias ordering

- First external modules (ie: dependencies)
- Then "special" modules (First `HELL.*` and then `Helix.Event`)
- Then modules from other domains
- Then modules from same domain

All alphabetically ordered.

Eg: (assuming we are on the Account domain)

```elixir
alias Comeonin.Bcrypt
alias HELL.PK
alias HELL.IP
alias Helix.Event
alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
alias Helix.Server.Action.Server, as: ServerAction
alias Helix.Server.Model.Server
alias Helix.Server.Query.Server, as: ServerQuery
alias Helix.Account.Model.Account
```

Open questions:

- How to deal with really large sub modules, like process/TOP and Universe/NPC?
  - Sug: Add sub-module name as sufix. Eg: ServerResourcesTOP
  - Sug: Use composed module names. Eg: `alias Helix.Process.TOP`; `TOP.ServerResources`
