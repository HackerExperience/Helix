alias Helix.Entity.Repo
alias Helix.Entity.Model.EntityType

Repo.transaction fn ->
  ["account", "npc", "clan"]
  |> Enum.map(&EntityType.create_changeset(%{entity_type: &1}))
  |> Enum.each(&Repo.insert!/1)
end