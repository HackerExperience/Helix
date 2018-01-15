defmodule Helix.Process.Public.View.Process.Helper do
  @moduledoc """
  Helper functions for `ProcessView` and `ProcessViewable`.
  """

  import HELL.Macros

  alias HELL.ClientUtils
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Software.Model.File
  alias Helix.Software.Query.File, as: FileQuery
  alias Helix.Process.Model.Process
  alias Helix.Process.Public.View.Process, as: ProcessView

  @spec default_process_render(Process.t, :partial) ::
    ProcessView.partial_process
  @spec default_process_render(Process.t, :full) ::
    ProcessView.full_process
  @doc """
  Most of the time, the process will want to render the default process for both
  `:local` and `:remote` contexts. If that's the case, simply call
  `default_process_render/2` and carry on.
  """
  def default_process_render(process, :partial) do
    partial = %{
      source_connection_id: nil,
      target_connection_id: nil
    }

    common = default_process_common(process, :partial)

    Map.merge(common, %{access: partial})
  end
  def default_process_render(process, :full) do
    source_connection_id =
      process.src_connection_id && to_string(process.src_connection_id)
    target_connection_id =
      process.tgt_connection_id && to_string(process.tgt_connection_id)

    usage = build_usage(process)
    source_file = build_file(process.src_file_id, :full)

    # OPTIMIZE: Possibly cache `origin_ip` and `target_ip` on the Process.t
    # It's used on several other places and must be queried every time it's
    # displayed.
    origin_ip = ServerQuery.get_ip(process.gateway_id, process.network_id)

    full = %{
      origin_ip: origin_ip,
      priority: process.priority,
      usage: usage,
      source_connection_id: source_connection_id,
      target_connection_id: target_connection_id,
      source_file: source_file
    }

    common = default_process_common(process, :full)

    Map.merge(common, %{access: full})
  end

  @spec get_default_scope(term, Process.t, Server.id, Entity.id) ::
    ProcessView.scopes
  def get_default_scope(_, %{gateway_id: server}, server, _),
    do: :full
  def get_default_scope(_, %{source_entity_id: entity}, _, entity),
    do: :full
  def get_default_scope(_, _, _, _),
    do: :partial

  @spec default_process_common(Process.t, ProcessView.scopes) ::
    partial_process_data :: term
  docp """
  This helper method renders process stuff which is common to both contexts
  (remote and local).
  """
  defp default_process_common(process, type) do
    network_id = process.network_id && to_string(process.network_id)

    target_file = build_file(process.tgt_file_id, type)
    progress = build_progress(process)
    target_ip = get_target_ip(process)

    %{
      process_id: to_string(process.process_id),
      target_file: target_file,
      progress: progress,
      state: to_string(process.state),
      network_id: network_id,
      target_ip: target_ip,
      type: to_string(process.type)
    }
  end

  @spec build_file(File.id | nil, ProcessView.scopes) ::
    ProcessView.file
  docp """
  Given the process file ID, builds up the `file` object that will be sent to
  the client.
  """
  defp build_file(nil, _),
    do: %{}
  defp build_file(file_id, :full) do
    file_id
    |> build_file_common()
    |> Map.put(:id, to_string(file_id))
  end
  defp build_file(file_id, :partial),
    do: build_file_common(file_id)

  docp """
  It's possible that a file related to a process has been deleted and the
  relevant process hasn't yet been notified - or never will, in which case it's
  reasonable to have an "Unknown file" as fallback.
  """
  defp build_file_common(file_id) do
    file = FileQuery.fetch(file_id)

    file_name =
      file
      && file.name
      || "Unknown file"

    %{
      name: file_name,
      version: nil
    }
  end

  @spec build_progress(Process.t) ::
    ProcessView.progress
  defp build_progress(process = %Process{}) do
    completion_date =
      if process.completion_date do
        ClientUtils.to_timestamp(process.completion_date)
      else
        nil
      end

    %{
      percentage: process.percentage,
      completion_date: completion_date,
      creation_date: ClientUtils.to_timestamp(process.creation_time)
    }
  end

  @spec build_usage(Process.t) ::
    ProcessView.resources
  defp build_usage(_process = %Process{}) do
    %{
      cpu: %{percentage: 0.0, absolute: 0},
      ram: %{percentage: 0.0, absolute: 0},
      dlk: %{percentage: 0.0, absolute: 0},
      ulk: %{percentage: 0.0, absolute: 0}
    }
  end

  @spec get_target_ip(Process.t) ::
    String.t
  defp get_target_ip(process = %Process{}) do
    case CacheQuery.from_server_get_nips(process.target_id) do
      {:ok, nips} ->
        nips
        |> Enum.find(&(&1.network_id == process.network_id))
        |> Map.get(:ip)
        |> to_string()

      {:error, _} ->
        "Unknown IP"
    end
  end
end
