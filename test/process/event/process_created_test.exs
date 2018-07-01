defmodule Helix.Process.Event.Process.CreatedTest do

  use Helix.Test.Case.Integration

  alias Helix.Event.Publishable

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Process.View.Helper, as: ProcessViewHelper

  describe "Publishable.whom_to_publish/1" do
    test "servers are listed correctly" do
      event = EventSetup.Process.created()

      assert %{server: [event.gateway_id, event.target_id]} ==
        Publishable.whom_to_publish(event)
    end
  end

  describe "Publishable.generate_payload/2" do
    test "single server process create (player AT action_server)" do
      socket = ChannelSetup.mock_server_socket(own_server: true)

      gateway_id = socket.assigns.gateway.server_id
      entity_id = socket.assigns.gateway.entity_id

      # Player doing an action on his own server
      event =
        EventSetup.Process.created(
          gateway_id: gateway_id,
          target_id: gateway_id,
          entity_id: entity_id,
          type: :bruteforce
        )

      assert {:ok, data} = Publishable.generate_payload(event, socket)

      ProcessViewHelper.assert_keys(data, :full)
    end

    test "multi server process create (attacker AT attack_source)" do
      socket = ChannelSetup.mock_server_socket()

      attack_source_id = socket.assigns.gateway.server_id
      attacker_entity_id = socket.assigns.gateway.entity_id
      attack_target_id = socket.assigns.destination.server_id

      # Simulate event between `attacker` and `victim`
      event =
        EventSetup.Process.created(
          gateway_id: attack_source_id,
          target_id: attack_target_id,
          entity_id: attacker_entity_id,
          type: :bruteforce
        )

      # Event originated on attack_source
      assert event.gateway_id == attack_source_id

      # Action happens on a remote server
      refute event.target_id == attack_source_id

      # Attacker has full access to the output payload
      assert {:ok, data} = Publishable.generate_payload(event, socket)

      ProcessViewHelper.assert_keys(data, :full)
    end

    test "multi server process create (attacker AT attack_target)" do
      socket = ChannelSetup.mock_server_socket()

      attacker_entity_id = socket.assigns.gateway.entity_id
      attack_source_id = socket.assigns.gateway.server_id
      attack_target_id = socket.assigns.destination.server_id

      # Simulate event between `attacker` and `victim`
      event =
        EventSetup.Process.created(
          gateway_id: attack_source_id,
          target_id: attack_target_id,
          entity_id: attacker_entity_id,
          type: :bruteforce
        )

      # Attacker has full access to the output payload
      assert {:ok, data} = Publishable.generate_payload(event, socket)

      ProcessViewHelper.assert_keys(data, :full)
    end

    test "multi server process create (third AT attack_source)" do
      # `attacker` is doing some nasty stuff on someone
      socket = ChannelSetup.mock_server_socket()
      attacker_entity_id = socket.assigns.gateway.entity_id
      attack_source_id = socket.assigns.gateway.server_id

      # Third is absolutely random to `attacker`. But `third` is connected to
      # `attacker`. In the socket created below, `attacker` is the destination
      # of `third`.
      third_socket =
        ChannelSetup.mock_server_socket(destination_id: attack_source_id)
      third_server_id = third_socket.assigns.gateway.server_id

      # Simulate event/action from `attack_source` to `attack_target`
      event =
        EventSetup.Process.created(
          gateway_id: attack_source_id,
          target_id: ServerHelper.id(),
          entity_id: attacker_entity_id,
          type: :bruteforce
        )

      # Attack originated on `attack_source`, owned by `attacker`
      assert event.gateway_id == attack_source_id
      refute third_server_id == attack_source_id

      # And it targets `attack_target`, totally unrelated to `third`
      refute event.target_id == third_server_id

      # Generates the payload as if `third` was receiving it
      assert {:ok, data} = Publishable.generate_payload(event, third_socket)

      # Third can see the full process, since the process originated at
      # `attack_source` and `third` is connected to `attack_source`.
      ProcessViewHelper.assert_keys(data, :full)
    end

    test "multi server process create (third AT attack_target)" do
      # `victim` is being attacked by someone
      socket = ChannelSetup.mock_server_socket()
      attacker_entity_id = socket.assigns.gateway.entity_id
      attack_target_id = socket.assigns.destination.server_id

      # Third is absolutely random to `victim`. But `third` is connected to
      # `victim`. In the socket created below, `victim` is the destination
      # of `third`.
      third_socket =
        ChannelSetup.mock_server_socket(destination_id: attack_target_id)

      # Simulate event/action from random `attacker` targeting `victim`.
      event =
        EventSetup.Process.created(
          gateway_id: ServerHelper.id(),
          target_id: attack_target_id,
          entity_id: attacker_entity_id,
          type: :bruteforce
        )

      # `third` never gets the publication
      assert {:ok, data} = Publishable.generate_payload(event, third_socket)

      # Third-party can see the process exists, but not who created it.
      ProcessViewHelper.assert_keys(data, :partial)
    end
  end
end
