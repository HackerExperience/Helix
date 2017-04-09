defmodule Helix.Account.Websocket.Controller.Account do

  alias Helix.Account.Service.API.Session

  @typep json_response ::
    {:ok, map}
    | {:error, map}

  @spec logout(%{session: Session.session}, map) ::
    json_response
  def logout(%{session: session}, _) do
    Session.invalidate_session(session)

    {:ok, %{}}
  end
end
