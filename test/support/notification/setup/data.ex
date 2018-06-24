defmodule Helix.Test.Notification.Setup.Data do

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Helper, as: ServerHelper

  def generate(:account, :server_password_acquired) do
    data =
      %{
        network_id: NetworkHelper.id(),
        ip: NetworkHelper.ip(),
        password: ServerHelper.password()
      }

    {data, %{}}
  end

  def generate(:server, :file_downloaded) do
    data = %{}

    extra =
      %{
        network_id: NetworkHelper.id(),
        ip: NetworkHelper.ip()
      }

    {data, extra}
  end
end
