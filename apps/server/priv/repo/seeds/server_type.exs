alias Helix.Server.Repo
alias Helix.Server.Model.ServerType

Repo.transaction fn ->
  ["desktop", "mobile", "vps"]
  |> Enum.map(&ServerType.create_changeset(%{server_type: &1}))
  |> Enum.each(&Repo.insert!/1)
end