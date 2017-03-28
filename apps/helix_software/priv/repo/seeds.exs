alias Helix.Software.Repo
alias Helix.Software.Model.SoftwareType
alias Helix.Software.Model.SoftwareModule

types = [
  %{
    software_type: "cracker",
    extension: "crc",
    modules: ["password"]
  },
  %{
    software_type: "exploit",
    extension: "exp",
    modules: ["ftp", "ssh"]
  },
  %{
    software_type: "firewall",
    extension: "fwl",
    modules: ["active", "passive"]
  },
  %{
    software_type: "hasher",
    extension: "hash",
    modules: ["password"]
  },
  %{
    software_type: "log_forger",
    extension: "logf",
    modules: ["create", "edit"]
  },
  %{
    software_type: "log_recover",
    extension: "logr",
    modules: ["recover"]
  },
  %{
    software_type: "encryptor",
    extension: "enc",
    modules: ["file", "log", "connection", "process"]
  },
  %{
    software_type: "decryptor",
    extension: "dec",
    modules: ["file", "log", "connection", "process"]
  },
  %{
    software_type: "anymap",
    extension: "map",
    modules: ["geo", "inbound", "outbound"]
  }
]

Repo.transaction fn ->
  Enum.each(types, fn type ->
    type
    |> Map.take([:software_type, :extension])
    |> SoftwareType.create_changeset()
    |> Repo.insert!(on_conflict: :nothing)
  end)

  modules = Enum.flat_map(types, fn type ->
    Enum.map(type.modules, fn module_name ->
      %{
        software_type: type.software_type,
        software_module: type.software_type <> "_" <> module_name
      }
    end)
  end)

  Enum.each(modules, fn module ->
    module
    |> SoftwareModule.create_changeset()
    |> Repo.insert!()
  end)
end
