defmodule Helix.Maroto.Playstate do

  use Helix.Maroto

  import Helix.Maroto.Functions

  @type state1 ::
    %{
      player: peer,
      dilma: peer,
      temer: peer
    }

  @typep peer ::
    %{
      account: Account.t,
      login: %{email: String.t, user: String.t, pass: String.t},
      entity: Entity.t,
      desktop: desktop_server,
      story: story_server
    }

  @typep desktop_server ::
    %{
      server: Server.t,
      ip: Network.ip
    }

  @typep story_server ::
    %{
      server: Server.t,
      ip: Network.ip,
      network_id: Network.id
    }

  @doc """
  Creates a simplified simulation

  Peers:
    - Aecio
    - Dilma
    - Temer

  Facts:
    1. Aecio has both Dilma and Temer on the Hacked Database.
    2. Aecio has an active SSH connection with Dilma.
    3. Aecio has a Spyware virus installed on Dilma.
  """
  def one do
    # Setup peers
    state =
      %{}
      |> setup_peer(:aecio)
      |> setup_peer(:dilma)
      |> setup_peer(:temer)

    # Helpers

    aecio_entity = state.aecio.entity
    aecio_server = state.aecio.desktop.server

    _dilma_entity = state.dilma.entity
    dilma_server = state.dilma.desktop.server

    _temer_entity = state.temer.entity
    temer_server = state.temer.desktop.server

    # Fact 1

    database_server_add(aecio_entity, dilma_server)
    database_server_add(aecio_entity, temer_server)

    # Fact 2

    connection_add(aecio_server, dilma_server, :ssh)

    state
  end

  defp setup_peer(state, id) do
    state = Map.put_new(state, id, %{desktop: %{}, story: %{}})

    {player, player_related} = create_account()

    state =
      state
      |> put_in([id, :account], player)
      |> put_in([id, :login], player_related)

    entity =
      player.account_id
      |> EntityQuery.get_entity_id()
      |> EntityQuery.fetch()

    servers =
      entity.entity_id
      |> EntityQuery.get_servers()
      |> Enum.map(&ServerQuery.fetch/1)

    server_desktop = Enum.find(servers, &(&1.type == :desktop))
    [server_desktop_nip] = ServerHelper.get_all_nips(server_desktop)

    server_story = Enum.find(servers, &(&1.type == :desktop_story))
    [server_story_nip] = ServerHelper.get_all_nips(server_story)

    state =
      state
      |> put_in([id, :entity], entity)
      |> put_in([id, :desktop, :server], server_desktop)
      |> put_in([id, :desktop, :ip], server_desktop_nip.ip)
      |> put_in([id, :story, :server], server_story)
      |> put_in([id, :story, :network_id], server_story_nip.network_id)
      |> put_in([id, :story, :ip], server_story_nip.ip)

    state
  end
end
