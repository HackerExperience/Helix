alias Helix.Software.Repo
alias Helix.Software.Model.FileType
alias Helix.Software.Model.SoftwareModule

types = [
  %{
    file_type: "cracker",
    extension: "crc",
    modules: ["password"]
  },
  %{
    file_type: "exploit",
    extension: "exp",
    modules: ["ftp", "ssh"]
  },
  %{
    file_type: "firewall",
    extension: "fwl",
    modules: ["active", "passive"]
  },
  %{
    file_type: "hasher",
    extension: "hash",
    modules: ["password"]
  },
  %{
    file_type: "log_forger",
    extension: "logf",
    modules: ["create", "edit"]
  },
  %{
    file_type: "log_recover",
    extension: "logr",
    modules: ["recover"]
  },
  %{
    file_type: "encryptor",
    extension: "enc",
    modules: ["file", "log", "connection", "process"]
  },
  %{
    file_type: "decryptor",
    extension: "dec",
    modules: ["file", "log", "connection", "process"]
  },
  %{
    file_type: "anymap",
    extension: "map",
    modules: ["geo", "inbound", "outbound"]
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
    |> SoftwareModule.create_changeset()
    |> Repo.insert!(on_conflict: :nothing)
  end)
end