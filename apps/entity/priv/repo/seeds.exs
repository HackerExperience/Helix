alias Helix.Entity.Repo
alias Helix.Entity.Model.EntityType

Repo.transaction fn ->
  Enum.each(EntityType.possible_types(), fn type ->
    Repo.insert!(%EntityType{entity_type: type}, on_conflict: :nothing)
  end)
end