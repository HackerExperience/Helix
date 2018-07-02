defmodule Helix.Notification.Model.Code.Account do

  use Helix.Notification.Model.Code

  code :server_password_acquired, 0 do
    @moduledoc """
    `ServerPasswordAcquiredNotification` is sent to the player right after a
    server's password is acquired. The server is identified by its NIP.
    """

    alias Helix.Network.Model.Network

    @doc false
    def generate_data(event) do
      %{
        network_id: event.network_id,
        ip: event.server_ip,
        password: event.password
      }
    end

    @doc false
    def after_read_hook(data) do
      %{
        network_id: Network.ID.cast!(data.network_id),
        ip: data.ip,
        password: data.password
      }
    end

    @doc false
    def render_data(data) do
      %{
        network_id: to_string(data.network_id),
        ip: data.ip,
        password: data.password
      }
    end
  end
end
