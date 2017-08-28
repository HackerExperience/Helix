defmodule Helix.Process.Model.Process.ProcessCreatedEventTest do

  use Helix.Test.Case.Integration

  alias Helix.Event.Notificable

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Event.Setup, as: EventSetup

  describe "Notificable.whom_to_notify/1" do
    test "for single-server processes" do
      event = EventSetup.process_created(:single_server)

      assert [notification_server] = Notificable.whom_to_notify(event)

      assert notification_server == event.gateway_id
    end

    test "for multi-server processes" do
      event = EventSetup.process_created(:multi_server)

      notification_list = Notificable.whom_to_notify(event)

      assert notification_list == [event.gateway_id, event.target_id]
    end
  end

  describe "Notificable.generate_payload/2" do
    test "single server process create (player AT action_server)" do
      socket = ChannelSetup.mock_server_socket([own_server: true])

      action_server = socket.assigns.gateway.server_id
      player_entity_id = socket.assigns.gateway.entity_id

      # Player doing an action on his own server
      event =
        EventSetup.process_created(
          :single_server,
          [gateway_id: action_server, gateway_entity_id: player_entity_id])

      assert {:ok, %{data: data}} =
        Helix.Event.Notificable.generate_payload(event, socket)

      assert_payload_full(data)
    end

    test "multi server process create (attacker AT attack_source)" do
      socket = ChannelSetup.mock_server_socket([own_server: true])

      attack_source = socket.assigns.gateway.server_id
      attacker_entity_id = socket.assigns.gateway.entity_id

      event =
        EventSetup.process_created(
          :multi_server,
          [gateway_id: attack_source, gateway_entity_id: attacker_entity_id])

      # Event originated on attack_source
      assert event.gateway_id == attack_source

      # Event attacker is attacker
      assert event.gateway_entity_id == attacker_entity_id

      # Action happens on a remote server
      refute event.target_id == attack_source

      # Which belongs to a different player
      refute event.target_entity_id == attacker_entity_id

      # Attacker has full access to the output payload
      assert {:ok, %{data: data}} =
        Helix.Event.Notificable.generate_payload(event, socket)

      assert_payload_full(data)
    end

    test "multi server process create (attacker AT attack_target)" do
      socket = ChannelSetup.mock_server_socket()

      attack_source = socket.assigns.gateway.server_id
      attack_target = socket.assigns.destination.server_id
      attacker_entity_id = socket.assigns.gateway.entity_id
      victim_entity_id = socket.assigns.destination.entity_id

      event =
        EventSetup.process_created(
          attack_source,
          attack_target,
          attacker_entity_id,
          victim_entity_id)

      # Attacker has full access to the output payload
      assert {:ok, %{data: data}} =
        Helix.Event.Notificable.generate_payload(event, socket)

      assert_payload_full(data)
    end

    test "multi server process create (victim AT attack_target)" do
      socket = ChannelSetup.mock_server_socket([own_server: true])

      attack_target = socket.assigns.gateway.server_id
      victim_entity_id = socket.assigns.gateway.entity_id

      event =
        EventSetup.process_created(
          :multi_server,
          [destination_id: attack_target,
           destination_entity_id: victim_entity_id])

      # Victim has full access to the output payload
      assert {:ok, %{data: data}} =
        Helix.Event.Notificable.generate_payload(event, socket)

      assert_payload_full(data)
    end

    test "multi server process create (victim AT attack_source)" do
      socket = ChannelSetup.mock_server_socket()

      attack_target = socket.assigns.gateway.server_id
      attack_source = socket.assigns.destination.server_id
      victim_entity_id = socket.assigns.gateway.entity_id
      attacker_entity_id = socket.assigns.destination.entity_id

      event =
        EventSetup.process_created(
          attack_source,
          attack_target,
          attacker_entity_id,
          victim_entity_id)

      # Victim has full access to the output payload
      assert {:ok, %{data: data}} =
        Helix.Event.Notificable.generate_payload(event, socket)

      assert_payload_full(data)
    end

    test "multi server process create (third AT attack_source)" do
      socket = ChannelSetup.mock_server_socket()

      third_server = socket.assigns.gateway.server_id
      third_entity_id = socket.assigns.gateway.entity_id
      attack_source = socket.assigns.destination.server_id
      attacker_entity_id = socket.assigns.destination.entity_id

      # Action from `attack_source` to `attack_target`
      event =
        EventSetup.process_created(
          :multi_server,
          [gateway_id: attack_source, gateway_entity_id: attacker_entity_id])

      # Attack originated on `attack_source`, owned by `attacker`
      assert event.gateway_id == attack_source
      refute third_server == attack_source

      # And it targets `attack_target`, totally unrelated to `third`
      refute event.target_id == third_server
      refute event.target_entity_id == third_entity_id

      # `third` sees everything
      assert {:ok, %{data: data}} =
        Helix.Event.Notificable.generate_payload(event, socket)

      # Third can see the full process, since it originated at `attack_source`
      assert_payload_full(data)
    end

    test "multi server process create (third AT attack_target)" do
      socket = ChannelSetup.mock_server_socket()

      attack_target = socket.assigns.destination.server_id
      victim_entity_id = socket.assigns.destination.entity_id

      # Action from `attack_source` to `attack_target`
      event =
        EventSetup.process_created(
          :multi_server,
          [destination_id: attack_target,
          destination_entity_id: victim_entity_id])

      # `third` never gets the notification
      assert {:ok, %{data: data}} =
        Helix.Event.Notificable.generate_payload(event, socket)

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
