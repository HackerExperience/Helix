defmodule Helix.Test.Log.Setup.LogType do

  alias Helix.Log.Model.LogType

  alias HELL.TestHelper.Random
  alias Helix.Test.Network.Helper, as: NetworkHelper

  @internet_id NetworkHelper.internet_id()

  @doc """
  Returns a random, valid log type.
  """
  def random_type,
    do: Enum.random(custom_types())

  @doc """
  Generates a Log.info based on the given opts.

  Opts:
    - type: What log type to use. Defaults to random one.
    - data_opts: What data_opts to pass to `data/2`. If not specified, the log
      data will be fake (generated randomly).
  """
  def log_info(opts) do
    type = Keyword.get(opts, :type, random_type())
    data = data(type, opts[:data_opts] || [])

    {type, LogType.new(type, data)}
  end

  @doc """
  Returns the corresponding data to the given log type
  """
  def data(:local_login, _data_opts),
    do: %{}

  def data(:remote_login_gateway, data_opts) do
    %{
      network_id: Keyword.get(data_opts, :network_id, @internet_id),
      ip: Keyword.get(data_opts, :ip, Random.ipv4())
    }
  end

  def data(:remote_login_endpoint, data_opts),
    do: data(:remote_login_gateway, data_opts)

  def data(:connection_bounced, data_opts) do
    %{
      ip_prev: Keyword.get(data_opts, :ip_prev, Random.ipv4()),
      ip_next: Keyword.get(data_opts, :ip_next, Random.ipv4()),
      network_id: Keyword.get(data_opts, :network_id, @internet_id)
    }
  end

  def data(:file_download_gateway, data_opts) do
    %{
      file_name: Keyword.get(data_opts, :file_name, Random.string(max: 8)),
      ip: Keyword.get(data_opts, :ip, Random.ipv4()),
      network_id: Keyword.get(data_opts, :network_id, @internet_id)
    }
  end

  def data(:file_download_endpoint, data_opts),
    do: data(:file_download_gateway, data_opts)

  defp custom_types do
    [
      :local_login,
      :remote_login_gateway,
      :remote_login_endpoint,
      :connection_bounced,
      :file_download_gateway,
      :file_download_endpoint
    ]
  end
end
