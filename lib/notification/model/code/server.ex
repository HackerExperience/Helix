defmodule Helix.Notification.Model.Code.Server do

  use Helix.Notification.Model.Code

  code :file_downloaded, 0 do
    @moduledoc """
    `FileDownloadedNotification` notifies the player that their download has
    just finished successfully.
    """

    alias Helix.Network.Model.Network
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
end
