defmodule Helix.Server.Websocket.Requests.Utils.Config do

  alias Helix.Server.Websocket.Requests.SetHostname, as: SetHostnameRequest
  alias Helix.Server.Websocket.Requests.Location, as: LocationRequest

  @valid_keys [:hostname, :location]
  @valid_keys_str Enum.map(@valid_keys, &to_string/1)

  def valid_keys,
    do: @valid_keys

  def valid_keys_str,
    do: @valid_keys_str

  def get_backend(:hostname),
    do: SetHostnameRequest
  def get_backend(:location),
    do: LocationRequest
end
