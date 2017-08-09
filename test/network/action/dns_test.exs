defmodule Helix.Network.Action.DNSTest do

  use Helix.Test.IntegrationCase

  alias Helix.Network.Action.DNS, as: DNSAction
  alias Helix.Network.Helper, as: NetworkHelper
  alias Helix.Network.Internal.DNS, as: DNSInternal
  alias Helix.Network.Model.Network

  defp unicast_params1,
    do: {NetworkHelper.internet_id(), "joelma.com", "1.1.1.1"}

  defp unicast_params2,
    do: {NetworkHelper.internet_id(), "chimbinha.com", "1.1.1.2"}

  describe "register_unicast/3" do
    test "it works when it works" do
      {network, site, ip} = unicast_params1()
      assert {:ok, _} = DNSAction.register_unicast(network, site, ip)

      assert DNSInternal.lookup_unicast(network, site)
    end

    test "it doesnt work when it doesnt work" do
      {network1, site1, ip1} = unicast_params1()
      {_, site2, _} = unicast_params2()
      assert {:ok, _} = DNSAction.register_unicast(network1, site1, ip1)
      assert {:error, _} = DNSAction.register_unicast(network1, site2, ip1)

      assert DNSInternal.lookup_unicast(network1, site1)
    end

    test "unicast is not anycast" do
      {network1, site1, ip1} = unicast_params1()
      {_, _, ip2} = unicast_params2()
      assert {:ok, _} = DNSAction.register_unicast(network1, site1, ip1)
      assert_raise Ecto.ConstraintError, fn ->
        DNSAction.register_unicast(network1, site1, ip2)
      end

      assert DNSInternal.lookup_unicast(network1, site1)
    end
  end

  describe "deregister_unicast/2" do
    test "it removes unicast entry" do
      {network, site, ip} = unicast_params1()

      # Add it to the DB
      assert {:ok, _} = DNSAction.register_unicast(network, site, ip)
      assert DNSInternal.lookup_unicast(network, site)

      DNSAction.deregister_unicast(network, site)

      # No longer there. It's magic!
      refute DNSInternal.lookup_unicast(network, site)
    end
  end

  describe "multiple networks on unicast" do
    test "it works" do
      {network1, site, ip} = unicast_params1()
      network2 = Network.ID.cast!("::2")

      # Registering on multiple networks
      assert {:ok, _} = DNSAction.register_unicast(network1, site, ip)
      assert {:ok, _} = DNSAction.register_unicast(network2, site, ip)

      # See? Equal but different
      name1 = DNSInternal.lookup_unicast(network1, site)
      name2 = DNSInternal.lookup_unicast(network2, site)
      refute name1 == name2

      # Removing one...
      DNSAction.deregister_unicast(network1, site)

      # ... won't affect the other
      refute DNSInternal.lookup_unicast(network1, site)
      assert DNSInternal.lookup_unicast(network2, site)
    end
  end
end
