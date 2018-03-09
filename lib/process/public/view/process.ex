defmodule Helix.Process.Public.View.Process do
  @moduledoc """
  `ProcessView` is a wrapper to the `ProcessViewable` protocol. Public methods
  interested on rendering a process (and as such using `ProcessViewable`) should
  use `ProcessView.render/4` instead.
  """

  alias HELL.HETypes
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Process.Model.Process
  alias Helix.Process.Public.View.ProcessViewable

  @type full_process :: process(full_access)
  @type partial_process :: process(partial_access)

  @type scopes ::
    :full
    | :partial

  @typep process(access) ::
    %{
      process_id: String.t,
      target_ip: String.t,
      network_id: String.t,
      progress: progress | nil,
      target_file: file,
      state: String.t,
      type: String.t,
      access: access
    }

  @typep full_access ::
    %{
      origin_ip: Network.ip,
      priority: 0..5,
      usage: resources,
      source_connection_id: String.t | nil,
      target_connection_id: String.t | nil,
      source_file: file
    }

  @typep partial_access ::
    %{
      source_connection_id: String.t | nil,
      target_connection_id: String.t | nil
    }

  @type file ::
    %{
      id: String.t | nil,
      name: String.t,
      version: float | nil
    }
    | nil

  @type progress ::
    %{
      percentage: float | nil,
      completion_date: HETypes.client_timestamp | nil,
      creation_date: HETypes.client_timestamp
    }

  @type resources ::
    %{
      cpu: resource_usage,
      ram: resource_usage,
      ulk: resource_usage,
      dlk: resource_usage
    }

  @typep resource_usage ::
    %{
      percentage: float,
      absolute: non_neg_integer
    }

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

    Map.merge(base, %{data: data})
  end
end
