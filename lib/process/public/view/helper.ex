defmodule Helix.Process.Public.View.Process.Helper do
  @moduledoc """
  Helper functions for `ProcessView` and `ProcessViewable`.
  """

  import HELL.Macros

  alias HELL.ClientUtils
  alias Helix.Cache.Query.Cache, as: CacheQuery
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
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
      connection_id: nil
    }

    common = default_process_common(process, :partial)

    Map.merge(common, %{access: partial})
  end
  def default_process_render(process, :full) do
    connection_id = process.connection_id && to_string(process.connection_id)
    usage = build_usage(process)

    partial = %{
      origin_id: to_string(process.gateway_id),
      priority: process.priority,
      usage: usage,
      connection_id: connection_id,
    }

    common = default_process_common(process, :full)

    Map.merge(common, %{access: partial})
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

    file = build_file(process.file_id, type)
    progress = build_progress(process)
    target_ip = get_target_ip(process)

    %{
      process_id: to_string(process.process_id),
      file: file,
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
  defp build_file(nil, _) do
    %{
      id: nil,
      name: "Unknown file",
      version: nil
    }
  end
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
      if process.estimated_time do
        ClientUtils.to_timestamp(process.estimated_time)
      else
        nil
      end

    %{
      percentage: 0.5,
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
