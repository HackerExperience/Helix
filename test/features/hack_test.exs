defmodule Helix.Test.Features.Hack do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Case.ID
  import Helix.Test.Macros

  alias HELL.Utils
  alias Helix.Entity.Query.Database, as: DatabaseQuery
  alias Helix.Network.Model.Connection
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Process.Model.Process
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Server.Websocket.Channel.Server, as: ServerChannel

  alias Helix.Test.Channel.Helper, as: ChannelHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  @moduletag :feature

  describe "crack" do
    test "crack (bruteforce) life cycle" do
      {socket, %{gateway: gateway, account: account}} =
        ChannelSetup.join_server([own_server: true])

      player_entity_id = socket.assigns.gateway.entity_id

      # Ensure we are listening to events on the Account channel too.
      ChannelSetup.join_account(
        [account_id: account.account_id, socket: socket])

      {target, _} = ServerSetup.server()

      target_nip = ServerHelper.get_nip(target)

      SoftwareSetup.file([type: :cracker, server_id: gateway.server_id])

      {bounce, _} = NetworkSetup.Bounce.bounce(entity_id: player_entity_id)

      params = %{
        network_id: to_string(target_nip.network_id),
        ip: target_nip.ip,
        bounce_id: to_string(bounce.bounce_id)
      }

      # Start the Bruteforce attack
      ref = push socket, "cracker.bruteforce", params

      # Wait for response
      assert_reply ref, :ok, %{data: %{}}, timeout(:slow)

      # Wait for generic ProcessCreatedEvent
      assert_push "event", _top_recalcado, timeout()
      assert_push "event", process_created, timeout()

      assert process_created.event == "process_created"

      process_id = Process.ID.cast!(process_created.data.process_id)
      connection_id =
        Connection.ID.cast!(process_created.data.access.source_connection_id)

      # The BruteforceProcess is running as expected
      process = ProcessQuery.fetch(process_id)

      assert process.gateway_id == gateway.server_id
      assert process.target_id == target.server_id
      assert process.type == :cracker_bruteforce
      assert process.data.target_server_ip == target_nip.ip

      tunnel =
        connection_id
        |> TunnelQuery.fetch_connection()
        |> TunnelQuery.fetch_from_connection()

      # Attack is using the requested bounce
      assert tunnel.gateway_id == gateway.server_id
      assert tunnel.target_id == target.server_id
      assert tunnel.bounce_id == bounce.bounce_id

      # Let's cheat and finish the process right now
      TOPHelper.force_completion(process)

      # And soon we'll receive the PasswordAcquiredEvent
      assert_push "event", password_acquired, timeout()
      assert password_acquired.event == "server_password_acquired"

      # Which includes data about the server we've just hacked!
      assert_id password_acquired.data.network_id, target_nip.network_id
      assert password_acquired.data.server_ip == target_nip.ip
      assert password_acquired.data.password

      # We'll receive the generic ProcessCompletedEvent
      assert_push "event", process_conclusion, timeout()
      assert process_conclusion.event == "process_completed"

      db_server =
        DatabaseQuery.fetch_server(
          player_entity_id, target_nip.network_id, target_nip.ip
        )

      # The hacked server has been added to my Database
      assert db_server
      assert db_server.password == password_acquired.data.password
      assert db_server.last_update > Utils.date_before(-1)

      # And I can actually login into the recently hacked server
      gateway_ip = ServerHelper.get_ip(gateway)

      topic =
        ChannelHelper.server_topic_name(target_nip.network_id, target_nip.ip)
      params = %{
        "gateway_ip" => gateway_ip,
        "password" => password_acquired.data.password
      }

      {:ok, %{data: bootstrap}, new_socket} =
        subscribe_and_join(socket, ServerChannel, topic, params)

      # I'm in!
      assert new_socket.topic == topic
      assert new_socket.assigns.gateway.server_id == gateway.server_id
      assert new_socket.assigns.destination.server_id == target.server_id

      # Logging in returns local server data, through bootstrap
      assert bootstrap.main_storage
      assert bootstrap.storages
      assert bootstrap.logs
      assert bootstrap.processes

      TOPHelper.top_stop(gateway)
    end
  end

  describe "remote login" do
    test "player can login another server when correct password is given" do
      {socket, %{gateway: gateway}} =
        ChannelSetup.join_server([own_server: true])

      {target, _} = ServerSetup.server()

      target_nip = ServerHelper.get_nip(target)

      gateway_ip = ServerHelper.get_ip(gateway)

      topic =
        ChannelHelper.server_topic_name(target_nip.network_id, target_nip.ip)
      params = %{
        "gateway_ip" => gateway_ip,
        "password" => target.password
      }

      # So, let's login!
      {:ok, %{data: bootstrap}, new_socket} =
        subscribe_and_join(socket, ServerChannel, topic, params)

      # Successfully joined the remote server channel
      assert new_socket.topic == topic
      assert new_socket.assigns.gateway.server_id == gateway.server_id
      assert new_socket.assigns.destination.server_id == target.server_id

      # Logging in returns the remote server data
      assert bootstrap.main_storage
      assert bootstrap.storages
      assert bootstrap.logs
      assert bootstrap.processes
    end

    @tag :pending
    test "server password is stored on the DB in case it wasn't already"
  end
end
