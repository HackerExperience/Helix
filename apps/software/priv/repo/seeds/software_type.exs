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
    roles: ["forge", "delete"]
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
  types
  |> Enum.map(fn t ->
    t
    |> Map.take([:file_type, :extension])
    |> FileType.create_changeset()
    |> Repo.insert!()

    t
  end)
  |> Enum.each(fn t ->
    t.roles
    |> Enum.each(fn r ->
      %{
        file_type: t.file_type,
        module_role: r}
      |> ModuleRole.create_changeset()
      |> Repo.insert!()
    end)
  end)
end