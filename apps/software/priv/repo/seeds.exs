alias Helix.Software.Repo
alias Helix.Software.Model.FileType
alias Helix.Software.Model.ModuleRole

types = [
  %{
    file_type: "cracker",
    extension: "crc",
    roles: ["password"]
  },
  %{
    file_type: "exploit",
    extension: "exp",
    roles: ["ftp", "ssh"]
  },
  %{
    file_type: "firewall",
    extension: "fwl",
    roles: ["active", "passive"]
  },
  %{
    file_type: "hasher",
    extension: "hash",
    roles: ["password"]
  },
  %{
    file_type: "log_forger",
    extension: "logf",
    roles: ["create", "edit"]
  },
  %{
    file_type: "log_recover",
    extension: "logr",
    roles: ["recover"]
  },
  %{
    file_type: "encryptor",
    extension: "enc",
    roles: ["file", "log", "connection", "process"]
  },
  %{
    file_type: "decryptor",
    extension: "dec",
    roles: ["file", "log", "connection", "process"]
  },
  %{
    file_type: "anymap",
    extension: "map",
    roles: ["geo", "inbound", "outbound"]
  }
]

Repo.transaction fn ->
  Enum.each(types, fn type ->
    type
    |> Map.take([:file_type, :extension])
    |> FileType.create_changeset()
    |> Repo.insert!(on_conflict: :nothing)
  end)

  roles = Enum.flat_map(types, fn type ->
    Enum.map(type.roles, &(%{file_type: type.file_type, module_role: &1}))
  end)

  Enum.each(roles, fn role ->
    role
    |> ModuleRole.create_changeset()
    |> Repo.insert!(on_conflict: :nothing)
  end)
end