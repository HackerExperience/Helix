defmodule Helix.Client.Public.Client do
  @moduledoc """
  `ClientPublic` is a giant dispatcher. It receives the currently connected
  `Client.t` and dispatches to the corresponding client implementation.
  """

  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Client.Model.Client
  alias Helix.Client.Web1.Public.Bootstrap, as: Web1Bootstrap

  alias Helix.Client.Event.Action.Performed, as: ClientActionPerformedEvent

  @typep bootstrap_result :: Web1Bootstrap.bootstrap
  @typep render_bootstrap_result :: Web1Bootstrap.rendered_bootstrap

  @spec bootstrap(Client.t, Entity.id) ::
    %{client: bootstrap_result}
  @doc """
  Generates the (arbitrary) client-specific bootstrap
  """
  def bootstrap(client, entity_id),
    do: %{client: dispatch(client, :bootstrap, entity_id)}

  @spec render_bootstrap(Client.t, %{client: bootstrap_result}) ::
    %{client: render_bootstrap_result}
  @doc """
  Renders the client bootstrap into a client-friendly format. Oh the irony.
  """
  def render_bootstrap(client, %{client: bootstrap}),
    do: %{client: dispatch(client, :render_bootstrap, bootstrap)}

  @spec broadcast_action(Client.t, Entity.id, Client.action) ::
    term
  @doc """
  Broadcasts to the world (i.e. Helix) that `action` has been performed by
  `entity_id`, which is using `client`.

  It's up to the handlers of the `ClientActionPerformedEvent` to determine what
  should be done with such information.

  Emits: `ClientActionPerformedEvent`
  """
  def broadcast_action(client, entity_id, action) do
    client
    |> ClientActionPerformedEvent.new(entity_id, action)
    |> Event.emit()
  end

  @spec dispatch(Client.t, :bootstrap, Entity.id) ::
    bootstrap_result
  defp dispatch(:web1, :bootstrap, entity_id),
    do: Web1Bootstrap.bootstrap(entity_id)
  defp dispatch(_, :bootstrap, _),
    do: %{}

  @spec dispatch(Client.t, :render_bootstrap, bootstrap_result) ::
    render_bootstrap_result
  defp dispatch(:web1, :render_bootstrap, bootstrap),
    do: Web1Bootstrap.render_bootstrap(bootstrap)
  defp dispatch(_, :render_bootstrap, _),
    do: %{}
end
