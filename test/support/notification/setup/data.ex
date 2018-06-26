defmodule Helix.Test.Notification.Setup.Data do

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Software.Helper, as: SoftwareHelper

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
    data =
      %{
        id: SoftwareHelper.id(),
        name: SoftwareHelper.random_file_name(),
        type: SoftwareHelper.random_file_type() |> to_string(),
        version: SoftwareHelper.random_version(),
        extension: SoftwareHelper.random_extension() |> to_string()
      }

    {data, %{}}
  end
end
