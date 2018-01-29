defmodule HELL.ClientUtils do

  alias HELL.HETypes
  alias Helix.Network.Model.Network

  @spec to_timestamp(DateTime.t) ::
    HETypes.client_timestamp
  @doc """
  Converts the given `DateTime.t` to the format expected by the client
  """
  def to_timestamp(datetime = %DateTime{}) do
    datetime
    |> DateTime.to_unix(:millisecond)
    |> Kernel./(1)  # Make it a float...
  end

  @spec to_nip(%{network_id: Network.id, ip: Network.ip}) :: HETypes.client_nip
  @spec to_nip(%{network_id: String.t, ip: String.t}) :: HETypes.client_nip
  @spec to_nip(Network.id, Network.ip) :: HETypes.client_nip
  @spec to_nip({Network.id, Network.ip}) :: HETypes.client_nip

  @doc """
  Generic method to convert a nip to the correct format expected by the client
  """
  def to_nip(nip = %{network_id: network_id, ip: _}) when is_binary(network_id),
    do: nip
  def to_nip(%{network_id: network_id = %Network.ID{}, ip: ip}),
    do: to_nip(network_id, ip)
  def to_nip({network_id = %Network.ID{}, ip}),
    do: %{network_id: to_string(network_id), ip: ip}
  def to_nip(network_id = %Network.ID{}, ip),
    do: %{network_id: to_string(network_id), ip: ip}
end
