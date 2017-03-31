defmodule Helix.Software.Model.SoftwareType do

  use Ecto.Schema

  @type t :: %__MODULE__{
    software_type: String.t,
    extension: String.t
  }

  @primary_key false
  schema "software_types" do
    field :software_type, :string,
      primary_key: true

    field :extension, :string
  end

  @doc false
  def possible_types do
    %{
      "cracker" => %{
        extension: "crc",
        modules: ["password"]
      },
      "exploit" => %{
        extension: "exp",
        modules: ["ftp", "ssh"]
      },
      "firewall" => %{
        extension: "fwl",
        modules: ["active", "passive"]
      },
      "hasher" => %{
        extension: "hash",
        modules: ["password"]
      },
      "log_forger" => %{
        extension: "logf",
        modules: ["create", "edit"]
      },
      "log_recover" => %{
        extension: "logr",
        modules: ["recover"]
      },
      "encryptor" => %{
        extension: "enc",
        modules: ["file", "log", "connection", "process"]
      },
      "decryptor" => %{
        extension: "dec",
        modules: ["file", "log", "connection", "process"]
      },
      "anymap" => %{
        extension: "map",
        modules: ["geo", "inbound", "outbound"]
      },
      "crypto_key" => %{
        extension: "key",
        modules: []
      }
    }
  end
end
