defmodule Helix.Notification.Model.Code.Server do

  use Helix.Notification.Model.Code

  code :file_downloaded, 0 do
    @moduledoc """
    `FileDownloadedNotification` notifies the player that their download has
    just finished successfully.
    """

    alias Helix.Software.Model.File
    alias Helix.Software.Public.Index, as: FileIndex

    @doc false
    def generate_data(event) do
      event.file
      |> FileIndex.render_file()
      |> Map.drop([:path, :size, :modules, :meta])
    end

    @doc false
    def after_read_hook(data) do
      %{
        id: File.ID.cast!(data.id),
        type: data.type,
        version: data.version,
        name: data.name,
        extension: data.extension
      }
    end

    @doc false
    def render_data(data),
      do: data
  end

  code :log_created, 4 do
    @moduledoc """
    `LogCreatedNotification` notifies the player that the LogForge.Create
    operation has finished successfully
    """

    alias Helix.Log.Model.Log

    @doc false
    def generate_data(event) do
      %{
        log_id: to_string(event.log.log_id)
      }
    end

    @doc false
    def after_read_hook(data) do
      %{
        log_id: Log.ID.cast!(data.log_id)
      }
    end

    @doc false
    def render_data(data),
      do: data
  end

  code :log_revised, 5 do
    @moduledoc """
    `LogRevisedNotification` notifies the player that the LogForge.Edit
    operation has finished successfully
    """

    alias Helix.Log.Model.Log

    @doc false
    def generate_data(event) do
      %{
        log_id: to_string(event.log.log_id)
      }
    end

    @doc false
    def after_read_hook(data) do
      %{
        log_id: Log.ID.cast!(data.log_id)
      }
    end

    @doc false
    def render_data(data),
      do: data
  end
end
