defmodule Helix.Process.Public.View.Process do
  @moduledoc """
  `ProcessView` is a wrapper to the `ProcessViewable` protocol. Public methods
  interested on rendering a process (and as such using `ProcessViewable`) should
  use `ProcessView.render/4` instead.
  """

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Process.Resources
  alias Helix.Process.Public.View.ProcessViewable

  @type partial_process ::
    %{
      :process_id => String.t,
      :gateway_id => String.t,
      :target_server_id => String.t,
      :file_id => String.t | nil,
      :network_id => String.t | nil,
      :connection_id => String.t | nil,
      :process_type => String.t
    }

  @type full_process ::
    %{
      :process_id => String.t,
      :gateway_id => String.t,
      :target_server_id => String.t,
      :file_id => String.t | nil,
      :network_id => String.t | nil,
      :connection_id => String.t | nil,
      :process_type => String.t,
      :state => String.t,
      :allocated => Resources.t,
      :priority => 0..5,
      :creation_time => String.t
    }

  @type scopes ::
    :full
    | :partial

  @spec render(data :: term, Process.t, Server.id, Entity.id) ::
    rendered_process :: term
  @doc """
  Renders the given process, according to the specified context (server, entity)

  It uses the `ProcessViewable` protocol internally, so for more details refer
  to its documentation.
  """
  def render(data, process, server_id, entity_id) do
    scope = ProcessViewable.get_scope(data, process, server_id, entity_id)
    {base, data} = ProcessViewable.render(data, process, scope)

    Map.merge(base, data)
  end
end
