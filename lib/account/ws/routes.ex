defmodule Helix.Account.WS.Routes do

  alias HELF.Router
  alias Helix.Account.WS.Controller.Account, as: AccountController

  @routes %{
    "account.create" => %{
      broker: "account.create",
      atoms: ~w/email username password/a
    },
    "account.login" => %{
      broker: "account.login",
      atoms: ~w/username password/a
    }
  }

  def register_routes do
    Enum.each(@routes, fn {topic, params} ->
      Router.register(topic, params.broker, params.atoms)
    end)
  end

  # This is a hack and only makes sense until we update Router to use Plug or
  # Phoenix.Channels
  @doc false
  def register_topics do
    account_create_fun = fn _pid, _topic, message, _request ->
      {:reply, AccountController.register(nil, message)}
    end
    HELF.Broker.subscribe("account.create", call: account_create_fun)

    account_login_fun = fn _pid, _topic, message, _request ->
      {:reply, AccountController.login(nil, message)}
    end
    HELF.Broker.subscribe("account.login", call: account_login_fun)
  end
end
