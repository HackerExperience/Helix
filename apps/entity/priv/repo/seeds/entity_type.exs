alias HELM.Entity.Repo
alias HELM.Entity.Model.EntityType

["account", "npc", "clan"]
|> Enum.map(&(EntityType.create_changeset(%{entity_type: &1})))
|> Enum.each(&Repo.insert!/1)