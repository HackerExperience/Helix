alias Helix.Hardware.Repo
alias Helix.Hardware.Model.ComponentType

Repo.transaction fn ->
  component_types = ["mobo", "cpu", "ram", "hdd", "usb", "nic"]

  component_types
  |> Enum.map(&(ComponentType.create_changeset(%{component_type: &1})))
  |> Enum.each(&Repo.insert!/1)
end