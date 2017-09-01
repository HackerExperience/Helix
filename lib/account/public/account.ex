defmodule Helix.Account.Public.Account do

  alias Helix.Entity.Query.Entity
  alias Helix.Server.Public.Server, as: ServerPublic
  alias Helix.Server.Query.Server, as: ServerQuery

  def bootstrap do
    boostrap = %{
      account: account_index(),
      servers: ServerPublic.server_index()
    }
  end

  def account_index do
    # %{
    #   servers: [],
    #   active_gateway: x
    # }
  end

end
