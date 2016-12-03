alias HELM.Server.Repo
alias HELM.Server.Model.ServerType

["desktop"]
|> Enum.map(&(ServerType.create_changeset(%{server_type: &1})))
|> Enum.each(&Repo.insert!/1)