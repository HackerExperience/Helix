defmodule Helix.Account.WS.Routes do

  alias HELF.Router

  @routes %{
    "account.create" => %{
      broker: "account.create",
      atoms: ~w/email username password/a
    },
    "account.login" => %{
      broker: "account.login",
      atoms: ~w/username password/
    }
  }

  def register_routes do
    Enum.each(@routes, fn {topic, params} ->
      Router.register(topic, params.broker, params.atoms)
    end)
  end
end