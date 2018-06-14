defmodule Helix.Client.Model.Client do

  alias Helix.Client.Web1.Model.Web1

  @type t :: client
  @type client ::
    :web1
    | :web2
    | :mobile1
    | :mobile2
    | :unknown

  @type action :: Web1.action

  @clients [:web1, :web2, :mobile1, :mobile2, :unknown]
  @clients_str Enum.map(@clients, &to_string/1)

  @spec valid_clients() ::
    [client]
  def valid_clients,
    do: @clients

  @spec valid_client?(binary | atom) ::
    boolean
  def valid_client?(client) when is_binary(client),
    do: client in @clients_str
  def valid_client?(client) when is_atom(client),
    do: client in @clients
end
