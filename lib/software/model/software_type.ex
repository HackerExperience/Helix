defmodule Helix.Software.Model.SoftwareType do

  use Ecto.Schema

  alias HELL.Constant

  @type t :: %__MODULE__{
    software_type: type,
    extension: String.t
  }

  @type type ::
    :cracker
    | :exploit
    | :firewall
    | :hasher
    | :log_forger
    | :log_recover
    | :encryptor
    | :decryptor
    | :anymap
    | :crypto_key

  # TODO: Add module types once file_module refactor is done

  @primary_key false
  schema "software_types" do
    field :software_type, Constant,
      primary_key: true

    field :extension, :string
  end

  @doc false
  def possible_types do
    %{
      text: %{
        extension: "txt",
        modules: []
      },
      cracker: %{
        extension: "crc",
        modules: [:bruteforce, :overflow]
      },
      exploit: %{
        extension: "exp",
        modules: [:exploit_ftp, :exploit_ssh]
      },
      firewall: %{
        extension: "fwl",
        modules: [:firewall_active, :firewall_passive]
      },
      hasher: %{
        extension: "hash",
        modules: [:hasher_password]
      },
      log_forger: %{
        extension: "logf",
        modules: [:log_forger_create, :log_forger_edit]
      },
      log_recover: %{
        extension: "logr",
        modules: [:log_recover_recover]
      },
      encryptor: %{
        extension: "enc",
        modules: [
          :encryptor_file,
          :encryptor_log,
          :encryptor_connection,
          :encryptor_process
        ]
      },
      decryptor: %{
        extension: "dec",
        modules: [
          :decryptor_file,
          :decryptor_log,
          :decryptor_connection,
          :decryptor_process
        ]
      },
      anymap: %{
        extension: "map",
        modules: [:anymap_geo, :anymap_inbound, :anymap_outbound]
      },
      crypto_key: %{
        extension: "key",
        modules: []
      }
    }
  end
end
