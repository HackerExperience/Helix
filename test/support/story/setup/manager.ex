defmodule Helix.Test.Story.Setup.Manager do

  alias Ecto.Changeset
  alias Helix.Story.Model.Story
  alias Helix.Story.Repo, as: StoryRepo

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Server.Helper, as: ServerHelper

  @doc """
  See docs on `fake_manager/1`
  """
  def manager(opts \\ []) do
    {manager, related} = fake_manager(opts)
    inserted = StoryRepo.insert!(manager)
    {inserted, related}
  end

  def manager!(opts \\ []) do
    {manager, _} = manager(opts)
    manager
  end

  @doc """
  - entity_id: Set entity whose Manager belongs to. Defaults to fake entity
  - server_id: Set server ID. Defaults to fake server
  - network_id: Set network ID. Defaults to fake network.
  - real_network: Whether to use a real network. Defaults to false.
  """
  def fake_manager(opts \\ []) do
    entity_id = Keyword.get(opts, :entity_id, EntityHelper.id())
    server_id = Keyword.get(opts, :server_id, ServerHelper.id())

    network_id =
      cond do
        opts[:real_network] ->
          {network, _} = NetworkSetup.network(type: :story)
          network.network_id

        opts[:network_id] ->
          opts[:network_id]

        true ->
          NetworkHelper.id()
      end

    manager =
      %Story.Manager{
        entity_id: entity_id,
        server_id: server_id,
        network_id: network_id
      }

    changeset = Changeset.change(manager)

    related =
      %{
        changeset: changeset
      }

    {manager, related}
  end
end
