defmodule Helix.Notification.Model.Code.Server do

  use Helix.Notification.Model.Code

  code :file_downloaded, 0 do
    @moduledoc """
    `FileDownloadedNotification` notifies the player that their download has
    just finished successfully.
    """

    alias Helix.Network.Model.Network

    # TODO: actual data
    def generate_data(event) do
      %{
      }
    end

    def after_read_hook(data) do
      %{
      }
    end

    def render_data(data) do
      %{
      }
    end
  end
end
