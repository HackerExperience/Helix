defmodule Helix.HTTPRouter do

  use Phoenix.Router

  alias Helix.Account.HTTP.Controller.Account

  import Phoenix.Controller

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", as: :api_v1 do
    pipe_through [:api]

    scope "/account" do
      post "/register", Account, :register

      post "/login", Account, :login
    end
  end
end
