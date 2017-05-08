defmodule Helix.HTTP.Router do

  use Phoenix.Router

  alias Helix.Account.HTTP.Controller, as: Account

  import Phoenix.Controller

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/v1", as: :api_v1 do
    pipe_through [:api]

    scope "/webhook" do
      scope "/migration" do
        post "/import", Account.Webhook, :import_from_migration
      end
    end

    scope "/account" do
      post "/register", Account.Account, :register

      post "/login", Account.Account, :login
    end
  end
end
