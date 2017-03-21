alias Helix.Software.Repo
alias Helix.Software.Model.SoftwareType
alias Helix.Software.Model.ModuleRole

types = [
  %{
    software_type: "cracker",
    extension: "crc",
    roles: ["password"]
  },
  %{
    software_type: "exploit",
    extension: "exp",
    roles: ["ftp", "ssh"]
  },
  %{
    software_type: "firewall",
    extension: "fwl",
    roles: ["active", "passive"]
  },
  %{
    software_type: "hasher",
    extension: "hash",
    roles: ["password"]
  },
  %{
    software_type: "log_forger",
    extension: "logf",
    roles: ["create", "edit"]
  },
  %{
    software_type: "log_recover",
    extension: "logr",
    roles: ["recover"]
  },
  %{
    software_type: "encryptor",
    extension: "enc",
    roles: ["file", "log", "connection", "process"]
  },
  %{
    software_type: "decryptor",
    extension: "dec",
    roles: ["file", "log", "connection", "process"]
  },
  %{
    software_type: "anymap",
    extension: "map",
    roles: ["geo", "inbound", "outbound"]
  }
]

Repo.transaction fn ->
  Enum.each(types, fn type ->
    type
    |> Map.take([:software_type, :extension])
    |> SoftwareType.create_changeset()
    |> Repo.insert!(on_conflict: :nothing)
  end)

  roles = Enum.flat_map(types, fn type ->
    Enum.map(type.roles, &(%{software_type: type.software_type, module_role: &1}))
  end)

  Enum.each(roles, fn role ->
    role
    |> ModuleRole.create_changeset()
    |> Repo.insert!(on_conflict: :nothing)
  end)
end