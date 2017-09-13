defmodule Helix.Test.Process.Data.Setup do

  alias Helix.Log.Model.Log
  alias Helix.Software.Model.Software.Cracker.Bruteforce, as: CrackerBruteforce
  alias Helix.Software.Model.SoftwareType.LogForge

  alias HELL.TestHelper.Random
  alias Helix.Test.Log.Helper, as: LogHelper

  @doc """
  Chooses a random implementation and uses it. Beware that `data_opts`, used by
  `custom/3`, is always an empty list.
  """
  def random(meta) do
    custom_implementations()
    |> Enum.take_random(1)
    |> custom([], meta)
  end

  @doc """
  Opts for bruteforce:
  - target_server_ip: Set target server IP.
  - real_ip: Whether to use the server real IP. Defaults to false.

  All others are automatically derived from process meta data.
  """
  def custom(:bruteforce, data_opts, meta) do
    target_server_id =
      Keyword.get(data_opts, :target_server_id, meta.target_server_id)
    target_server_ip =
      cond do
        data_opts[:target_server_ip] ->
          data_opts[:target_server_ip]
        data_opts[:real_ip] ->
          raise "todo"
        true ->
          Random.ipv4()
      end
    software_version = Keyword.get(data_opts, :software_version, 10)
    network_id = Keyword.get(data_opts, :network_id, meta.network_id)

    data = %CrackerBruteforce{
      network_id: network_id,
      target_server_id: target_server_id,
      target_server_ip: target_server_ip,
      software_version: software_version
    }

    {"cracker_bruteforce", data}
  end

  @doc """
  Opts for forge:
  - operation: :edit | :create. Defaults to :edit.
  - target_log_id: Which log to edit. Won't generate a real one.
  - message: Revision message.
  
  All others are automatically derived from process meta data.
  """
  def custom(:forge, data_opts, meta) do
    target_server_id = meta.target_server_id
    target_log_id = Keyword.get(data_opts, :target_log_id, Log.ID.generate())
    entity_id = meta.source_entity_id
    operation = Keyword.get(data_opts, :operation, :edit)
    message = LogHelper.random_message()
    version = 100

    data =
      %LogForge{
        target_server_id: target_server_id,
        entity_id: entity_id,
        operation: operation,
        message: message,
        version: version
      }

    data =
      if operation == :edit do
        Map.merge(data, %{target_log_id: target_log_id})
      else
        data
      end

    {"log_forger", data}
  end

  defp custom_implementations do
    ~w/
    bruteforce
    log_forge
    /a
  end
end
