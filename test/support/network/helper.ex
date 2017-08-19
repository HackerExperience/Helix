defmodule Helix.Test.Network.Helper do

  alias Helix.Network.Model.Network

  def internet_id,
    do: Network.ID.cast!("::")
end
