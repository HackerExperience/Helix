defmodule Helix.Hardware.Model.NetworkConnectionTest do

  use ExUnit.Case, async: true

  alias Helix.Network.Model.Network
  alias Helix.Hardware.Model.NetworkConnection

  @moduletag :unit

  test "requires network, downlink and uplink" do
    nc = NetworkConnection.create_changeset(%{})

    assert :network_id in Keyword.keys(nc.errors)
    assert :uplink in Keyword.keys(nc.errors)
    assert :downlink in Keyword.keys(nc.errors)

    params = %{
      network_id: Network.ID.generate(),
      uplink: 0,
      downlink: 0
    }

    nc2 = NetworkConnection.create_changeset(params)

    assert nc2.valid?
  end

  test "uplink and downlink should not be negative" do
    params = %{
      network_id: Network.ID.generate(),
      uplink: -1,
      downlink: -1
    }

    nc = NetworkConnection.create_changeset(params)

    assert :uplink in Keyword.keys(nc.errors)
    assert :downlink in Keyword.keys(nc.errors)
  end
end
