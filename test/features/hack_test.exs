defmodule Helix.Test.Features.Hack do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Case.ID

  alias HELL.Utils
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Query.Database, as: DatabaseQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Server.Websocket.Channel.Server, as: ServerChannel

  alias Helix.Test.Channel.Helper, as: ChannelHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup
  alias Helix.Test.Server.Setup, as: ServerSetup

  @moduletag :feature

  describe "crack" do
    test "crack (bruteforce) life cycle" do
      {socket, %{gateway: gateway, account: account}} =
        ChannelSetup.join_server([own_server: true])

      player_entity = EntityQuery.get_entity_id(account.account_id)

      # Ensure we are listening to events on the Account channel.
      ChannelSetup.join_account(
        [account_id: account.account_id, socket: socket])

      {target, _} = ServerSetup.server()

      {:ok, [source_nip]} = CacheQuery.from_server_get_nips(gateway.server_id)
      {:ok, [target_nip]} = CacheQuery.from_server_get_nips(target.server_id)

      SoftwareSetup.file([type: :cracker, server_id: gateway.server_id])

      params = %{
        network_id: to_string(target_nip.network_id),
        ip: target_nip.ip,
        bounces: []
      }

      # Start the Bruteforce attack
      ref = push socket, "bruteforce", params

      # Wait for response
      assert_reply ref, :ok, response

      # The response includes the Bruteforce process information
      assert response.data.process_id

      # Wait for generic ProcessCreatedEvent
      assert_push "event", process_created_event
      assert process_created_event.event == "process_created"

      # The BruteforceProcess is running as expected
      process = ProcessQuery.fetch(response.data.process_id)
      connection = TunnelQuery.fetch_connection(response.data.connection_id)
      assert process
      assert connection

      # Let's cheat and finish the process right now
      TOPHelper.force_completion(process)

      # We'll receive the generic ProcessConclusionEvent
      assert_push "event", process_conclusion_event
      assert process_conclusion_event.event == "process_conclusion"

      # And soon we'll receive the PasswordAcquiredEvent
      assert_push "event", password_acquired_event
      assert password_acquired_event.event == "server_password_acquired"

      # Which includes data about the server we've just hacked!
      assert_id password_acquired_event.data.network_id, target_nip.network_id
      assert password_acquired_event.data.server_ip == target_nip.ip
      assert password_acquired_event.data.password

      :timer.sleep(50)

      db_server =
        DatabaseQuery.fetch_server(
          player_entity,
          target_nip.network_id,
          target_nip.ip)

      # The hacked server has been added to my Database
      assert db_server
      assert db_server.password == password_acquired_event.data.password
      assert db_server.last_update > Utils.date_before(-1)

      # And I can actually login into the recently hacked server

      topic =
        ChannelHelper.server_topic_name(target_nip.network_id, target_nip.ip)
      params = %{
        "gateway_ip" => socket.assigns.gateway.ip,
        "password" => password_acquired_event.data.password
      }

      {:ok, _, new_socket} =
        subscribe_and_join(socket, ServerChannel, topic, params)

      # I'm in!
      assert new_socket.topic == topic
      assert new_socket.assigns.gateway.server_id == gateway.server_id
      assert new_socket.assigns.destination.server_id == target.server_id

      :timer.sleep(50)

      TOPHelper.top_stop(gateway.server_id)
    end
  end

  describe "remote login" do
    test "player can login another server when correct password is given" do
      {socket, %{gateway: gateway}} =
        ChannelSetup.join_server([own_server: true])

      {target, _} = ServerSetup.server()

      {:ok, [target_nip]} = CacheQuery.from_server_get_nips(target.server_id)

      # To the client, login consists of two steps:
      #  1 - Joining the remote server channel
      #  2 - Retrieving data about the remote server
      # To the backend, `login` is simply the act of joining another server's
      # channel (step 1 above).

      topic =
        ChannelHelper.server_topic_name(target_nip.network_id, target_nip.ip)
      params = %{
        "gateway_ip" => socket.assigns.gateway.ip,
        "password" => target.password
      }

      # So, let's login!
      {:ok, _, new_socket} =
        subscribe_and_join(socket, ServerChannel, topic, params)

      # Successfully joined the remote server channel
      assert new_socket.topic == topic
      assert new_socket.assigns.gateway.server_id == gateway.server_id
      assert new_socket.assigns.destination.server_id == target.server_id

      # Now let's retrieve information about that server

      :timer.sleep(50)
    end

    @tag :pending
    test "server password is stored on the DB in case it wasn't already"
  end
end
