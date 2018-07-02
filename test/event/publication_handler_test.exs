defmodule Helix.Event.PublicationHandlerTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Case.ID
  import Helix.Test.Channel.Macros
  import Helix.Test.Macros
  import Helix.Test.Event.Macros

  alias Helix.Process.Model.Process

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup
  alias Helix.Test.Event.Helper, as: EventHelper
  alias Helix.Test.Event.Setup, as: EventSetup

  @moduletag :driver

  # Behold, adventurer! The tests below are meant to ensure
  # `publication_handler/1` works correctly under the hood, as well as Phoenix
  # behavior of intercepting and filtering out an event.
  # It is not mean to extensively test all events. For this, refer to the
  # specific event's test file.
  # As such, we use `ProcessCreatedEvent` here merely as an example. Peace.
  describe "publication_handler/1" do
    test "publishes to gateway that a process was created (single-server)" do
      {_socket, %{gateway: gateway}} =
        ChannelSetup.join_server(own_server: true)

      # Remove the `LogCreatedEvent` from the queue (so it won't affect tests)
      assert_broadcast "event", _log_created_event

      event =
        EventSetup.Process.created(
          gateway_id: gateway.server_id,
          target_id: gateway.server_id,
          type: :bruteforce
        )

      # Process happens on the same server
      assert event.gateway_id == event.target_id

      EventHelper.emit(event)

      # Broadcast is before inspecting the event with `handle_out`, so this
      # isn't the final output to the client
      assert_broadcast "event", internal_broadcast, timeout()
      assert_event internal_broadcast, event

      # Now that's what the client actually receives.
      [publication] = wait_events [:process_created]
      assert publication.event == "process_created"

      process = publication.data

      # Make sure all we need is on the process return
      assert_id process.process_id, event.process.process_id
      assert process.type == event.process.type |> to_string()
      assert_id process.access.source_file.id, event.process.src_file_id
      assert_id \
        process.access.source_connection_id, event.process.src_connection_id
      assert_id process.network_id, event.process.network_id
      assert process.target_ip

      # Event id was generated
      assert publication.meta.event_id
      assert is_binary(publication.meta.event_id)

      # No process ID
      refute publication.meta.process_id
    end

    test "multi-server" do
      {_, %{gateway: gateway, destination: destination}} =
        ChannelSetup.join_server()

      # Filter out the usual `LogCreatedEvent` after remote server join
      assert_broadcast "event", _, timeout()

      event =
        EventSetup.Process.created(
          gateway_id: gateway.server_id,
          target_id: destination.server_id,
          type: :bruteforce
        )

      # Process happens on two different servers
      refute event.gateway_id == event.target_id

      EventHelper.emit(event)

      # Broadcast is before inspecting the event with `handle_out`, so this
      # isn't the final output to the client
      assert_broadcast "event", internal_broadcast, timeout()
      assert_event internal_broadcast, event

      # Now that's what the client actually receives.
      [publication] = wait_events [:process_created]
      assert publication.event == "process_created"

      process = publication.data

      # Make sure all we need is on the process return
      assert_id process.process_id, event.process.process_id
      assert process.type == event.process.type |> to_string()
      assert_id \
        process.access.source_connection_id, event.process.src_connection_id
      assert_id process.network_id, event.process.network_id
      assert process.target_ip

      # Event id was generated
      assert publication.meta.event_id
      assert is_binary(publication.meta.event_id)

      # No process id
      refute publication.meta.process_id
    end

    # This test is meant to verify that, on process completion, all events
    # coming out from the process have the `process_id` added to the event's
    # `__meta__`. Sadly, current TOP interface does not allow for an easy
    # testing of this, so this test is done at a much higher level. Revisit
    # these tests once TOP gets rewritten (#291).
    test "inheritance of process id" do
      {socket, %{gateway: gateway, account: account}} =
          ChannelSetup.join_server([own_server: true])

      # Ensure we are listening to events on the Account channel too.
      ChannelSetup.join_account(
        [account_id: account.account_id, socket: socket])

      # Remove the `LogCreatedEvent` from the queue (so it won't affect tests)
      assert_broadcast "event", _log_created_event

      {target, _} = ServerSetup.server()

      target_nip = ServerHelper.get_nip(target)

      SoftwareSetup.file([type: :cracker, server_id: gateway.server_id])

      params = %{
        network_id: to_string(target_nip.network_id),
        ip: target_nip.ip,
        bounce_id: nil
      }

      # Start the Bruteforce attack
      ref = push socket, "cracker.bruteforce", params
      assert_reply ref, :ok, %{}, timeout(:slow)

      # Wait for generic ProcessCreatedEvent
      [process_created_event] = wait_events [:process_created]

      assert process_created_event.event == "process_created"
      process_id = Process.ID.cast!(process_created_event.data.process_id)

      # Let's cheat and finish the process right now
      TOPHelper.force_completion(process_id)

      # Intercept Helix internal events.
      # Note these events won't (necessarily) go out to the Client, they will
      # be intercepted and may be filtered out if they do not implement the
      # Publishable protocol.
      # We are getting them here so we can inspect the actual metadata of
      # both `ProcessCompletedEvent` and `PasswordAcquiredEvent`
      assert_broadcast "event", _top_recalcado_event, timeout()
      assert_broadcast "event", _process_created_t, timeout()
      assert_broadcast "event", _process_created_f, timeout()
      assert_broadcast "event", server_password_acquired_event, timeout()
      assert_broadcast "event", _notification_added_event, timeout()
      assert_broadcast "event", process_completed_event, timeout()

      # They have the process IDs!
      assert process_id == process_completed_event.__meta__.process_id
      assert process_id == server_password_acquired_event.__meta__.process_id

      # We'll receive the PasswordAcquiredEvent and ProcessCompletedEvent
      [password_acquired_event, process_conclusion_event] =
        wait_events [:server_password_acquired, :process_completed]
      assert password_acquired_event.event == "server_password_acquired"

      # Which has a valid `process_id` on the event metadata!
      assert to_string(process_id) == password_acquired_event.meta.process_id

      # And if `ServerPasswordAcquiredEvent` has the process_id, then
      # `BruteforceProcessedEvent` have it as well, and as such TOP should be
      # working for all kinds of events.

      # As long as we are here, let's test that the metadata sent to the client
      # has been converted to JSON-friendly strings
      assert to_string(process_id) == process_conclusion_event.meta.process_id
    end
  end
end
