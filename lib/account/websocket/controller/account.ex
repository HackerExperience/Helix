defmodule Helix.Account.Websocket.Controller.Account do

  alias Helix.Account.Action.Session, as: SessionAction

  @typep json_response ::
    {:ok, map}
    | {:error, map}

  @spec logout(%{session: SessionAction.session}, map) ::
    json_response
  def logout(%{session: session}, _) do
    SessionAction.invalidate_session(session)

    {:ok, %{}}
  end
end
