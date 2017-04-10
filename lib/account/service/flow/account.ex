defmodule Helix.Account.Service.Flow.Account do

  alias HELL.PK
  alias Helix.Account.Model.Account
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Service.API.Entity, as: EntityAPI
  alias Helix.Hardware.Service.API.Bundle, as: BundleAPI
  alias Helix.Hardware.Service.API.Component, as: ComponentAPI
  alias Helix.Server.Service.API.Server, as: ServerAPI

  import HELF.Flow

  @spec setup(Account.id) :: any
  def setup(account_id) do
    # REVIEW: some API functions here are behaving weirdly, like
    # `ServerAPI.delete` not allowing `Server.t` (it requires `server_id`)
    flowing do
      with \
        {:ok, entity} <- EntityAPI.create(:account, account_id),
        on_fail(fn -> EntityAPI.delete(entity) end),

        {:ok, bundle} <- BundleAPI.create(),
        components = [bundle.motherboard | bundle.components],
        on_fail(fn -> Enum.each(components, &ComponentAPI.delete/1) end),

        {:ok, server} <- ServerAPI.create(:desktop),
        on_fail(fn -> ServerAPI.delete(server.server_id) end),

        {:ok, _} <- EntityAPI.link_server(entity, server.server_id),
        on_fail(fn -> EntityAPI.unlink_server(server.server_id) end),

        :ok <- link_entity_components(entity, components),
        on_fail(fn -> Enum.each(components, &EntityAPI.unlink_component/1) end),

        {:ok, server} <- ServerAPI.attach(server, bundle.motherboard),
        on_fail(fn -> ServerAPI.detach(server) end)
      do
        :ok
      end
    end
  end

  @spec link_entity_components(Entity.t, [PK.t]) ::
    :ok
    | :error
  defp link_entity_components(entity, components) do
    linked? = &match?({:ok, _}, EntityAPI.link_component(entity, &1))

    if Enum.all?(components, linked?),
      do: :ok,
      else: :error
  end
end
