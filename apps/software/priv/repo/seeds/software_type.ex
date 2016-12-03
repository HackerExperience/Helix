alias HELM.Software.Repo
alias HELM.Software.Model.FileType
alias HELM.Software.Model.ModuleRole

types = [
  %{
    file_type: "bitcoin_miner",
    extension: "bim",
    roles: ["efficiency", "install_speed"]
  },
  %{
    file_type: "spammer",
    extension: "spmr",
    roles: ["efficiency", "install_speed"]
  },
  %{
    file_type: "torrent",
    extension: "trr",
    roles: ["efficiency", "install_speed"]
  },
  %{
    file_type: "botnet",
    extension: "bot",
    roles: []
  },
  %{
    file_type: "cracker",
    extension: "crc",
    roles: []
  },
  %{
    file_type: "exploit",
    extension: "exp",
    roles: ["ftp", "ssh"]
  },
  %{
    file_type: "firewall",
    extension: "fwl",
    roles: ["protect", "retaliate"]
  },
  %{
    file_type: "password_hasher",
    extension: "hsh",
    roles: ["protect"]
  },
  %{
    file_type: "hider", # RENAME ME PL0X
    extension: "hdr",
    roles: ["file", "log", "process"]
  },
  %{
    file_type: "seeker", # RENAME ME TOO
    extension: "skr",
    roles: ["file", "log", "process"]
  },
  %{
    file_type: "hmap",
    extension: "hmap",
    roles: ["geo", "inbound", "outbound"]
  },
  %{
    file_type: "log_forge",
    extension: "lfg",
    roles: ["forge"]
  },
  %{
    file_type: "log_recover",
    extension: "lrcv",
    roles: ["recover"]
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