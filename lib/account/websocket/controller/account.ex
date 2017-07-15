defmodule Helix.Account.Websocket.Controller.Account do

  alias Helix.Account.Action.Session, as: SessionAction
  alias Helix.Account.Model.AccountSession

  @spec logout(%{session: AccountSession.session}, map) ::
    {:ok, %{}}
  def logout(%{session: session}, _) do
    SessionAction.invalidate_session(session)

    {:ok, %{}}
  end
end
