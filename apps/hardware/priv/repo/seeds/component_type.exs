alias HELM.Hardware.Repo
alias HELM.Hardware.Model.ComponentType

[
  "MOBO",
  "CPU",
  "RAM",
  "HDD"
  ]
|> Enum.map(&(ComponentType.create_changeset(%{entity_type: &1})))
|> Enum.each(&Repo.insert!/1)