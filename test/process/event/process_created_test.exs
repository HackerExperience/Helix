defmodule Helix.Process.Event.Process.CreatedTest do

  use Helix.Test.Case.Integration

  alias Helix.Event.Notificable
  alias Helix.Server.Model.Server

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Event.Setup, as: EventSetup

  describe "Notificable.whom_to_notify/1" do
    test "servers are listed correctly" do
      event = EventSetup.Process.created()

      assert %{server: [event.gateway_id, event.target_id]} ==
        Notificable.whom_to_notify(event)
    end
  end

  describe "Notificable.generate_payload/2" do
    test "single server process create (player AT action_server)" do
      socket = ChannelSetup.mock_server_socket([own_server: true])

      gateway_id = socket.assigns.gateway.server_id

      # Player doing an action on his own server
      event = EventSetup.Process.created(gateway_id)

      assert {:ok, data} = Notificable.generate_payload(event, socket)

      assert_payload_full(data)
    end

    test "multi server process create (attacker AT attack_source)" do
      socket = ChannelSetup.mock_server_socket()

      attack_source_id = socket.assigns.gateway.server_id

      event = EventSetup.Process.created(attack_source_id, Server.ID.generate())

      # Event originated on attack_source
      assert event.gateway_id == attack_source_id

      # Action happens on a remote server
      refute event.target_id == attack_source_id

      # Attacker has full access to the output payload
      assert {:ok, data} = Notificable.generate_payload(event, socket)

      assert_payload_full(data)
    end

    test "multi server process create (attacker AT attack_target)" do
      socket = ChannelSetup.mock_server_socket()

      attack_source_id = socket.assigns.gateway.server_id
      attack_target_id = socket.assigns.destination.server_id

      event = EventSetup.Process.created(attack_source_id, attack_target_id)

      # Attacker has full access to the output payload
      assert {:ok, data} = Notificable.generate_payload(event, socket)

      assert_payload_full(data)
    end

    test "multi server process create (third AT attack_source)" do
      socket = ChannelSetup.mock_server_socket()

      third_server_id = socket.assigns.gateway.server_id
      attack_source_id = socket.assigns.destination.server_id

      # Action from `attack_source` to `attack_target`
      event = EventSetup.Process.created(attack_source_id, Server.ID.generate())

      # Attack originated on `attack_source`, owned by `attacker`
      assert event.gateway_id == attack_source_id
      refute third_server_id == attack_source_id

      # And it targets `attack_target`, totally unrelated to `third`
      refute event.target_id == third_server_id

      # `third` sees everything
      assert {:ok, data} = Notificable.generate_payload(event, socket)

      # Third can see the full process, since it originated at `attack_source`
      assert_payload_full(data)
    end

    test "multi server process create (third AT attack_target)" do
      socket = ChannelSetup.mock_server_socket()

      target_id = socket.assigns.destination.server_id

      # Action from `attack_source` to `attack_target`
      event = EventSetup.Process.created(Server.ID.generate(), target_id)

      # `third` never gets the notification
      assert {:ok, data} = Notificable.generate_payload(event, socket)

      # Third-party can see the process exists, but not who created it.
      assert_payload_censored(data)
    end

    defp assert_payload_full(data) do
      expected_keys =
        [:process_id, :type, :network_id, :file_id, :source_ip, :target_ip,
         :connection_id]

      Enum.each(expected_keys, fn key ->
        assert Map.has_key?(data, key)
      end)
    end

    defp assert_payload_censored(data) do
      expected_keys = [:process_id, :type, :network_id, :file_id, :target_ip]
      rejected_keys = [:source_ip, :connection_id]

      Enum.each(expected_keys, fn key ->
        assert Map.has_key?(data, key)
      end)
      Enum.each(rejected_keys, fn key ->
        refute Map.has_key?(data, key)
      end)
    end
  end
end
