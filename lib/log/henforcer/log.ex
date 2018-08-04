defmodule Helix.Log.Henforcer.Log do

  import Helix.Henforcer

  alias Helix.Server.Model.Server
  alias Helix.Log.Model.Log
  alias Helix.Log.Query.Log, as: LogQuery

  @type log_exists_relay :: %{log: Log.t}
  @type log_exists_relay_partial :: %{}
  @type log_exists_error ::
    {false, {:log, :not_found}, log_exists_relay_partial}

  @spec log_exists?(Log.id) ::
    {true, log_exists_relay}
    | log_exists_error
  @doc """
  Henforces that the given `log_id` exists on the database.
  """
  def log_exists?(log_id = %Log.ID{}) do
    with log = %Log{} <- LogQuery.fetch(log_id) do
      reply_ok(%{log: log})
    else
      _ ->
        reply_error({:log, :not_found})
    end
  end

  @type belongs_to_server_relay :: %{}
  @type belongs_to_server_relay_partial :: %{}
  @type belongs_to_server_error ::
    {false, {:log, :not_belongs}, belongs_to_server_relay_partial}

  @spec belongs_to_server?(Log.t, Server.idt) ::
    {true, belongs_to_server_relay}
    | belongs_to_server_error
  @doc """
  Henforces that the given log belongs to the given server.
  """
  def belongs_to_server?(%Log{server_id: s}, %Server{server_id: s}),
    do: reply_ok()
  def belongs_to_server?(%Log{server_id: s}, s = %Server.ID{}),
    do: reply_ok()
  def belongs_to_server?(%Log{}, _),
    do: reply_error({:log, :not_belongs})
end
