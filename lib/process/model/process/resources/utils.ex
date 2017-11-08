defmodule Helix.Process.Model.Process.Resources.Utils do

  alias Helix.Network.Model.Network

  @spec format_network(Network.idtb, term) ::
  {Network.id, term}
  def format_network(key = %Network.ID{}, value),
    do: {key, value}
    def format_network(key, value),
      do: {Network.ID.cast!(key), value}
end
