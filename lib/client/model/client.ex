defmodule Helix.Client.Model.Client do

  @type t :: client
  @type client ::
    :web1
    | :web2
    | :mobile1
    | :mobile2
    | :unknown

  @clients [:web1, :web2, :mobile1, :mobile2, :unknown]
  @clients_str Enum.map(@clients, &to_string/1)

  def valid_clients,
    do: @clients

  def valid_client?(client) when is_binary(client),
    do: client in @clients_str
  def valid_client?(client) when is_atom(client),
    do: client in @clients
end
