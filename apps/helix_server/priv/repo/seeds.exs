alias Helix.Server.Repo
alias Helix.Server.Model.ServerType

Repo.transaction fn ->
  Enum.each(ServerType.possible_types(), fn type ->
    Repo.insert!(%ServerType{server_type: type}, on_conflict: :nothing)
  end)
end