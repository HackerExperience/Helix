defmodule HELM.Account.Controller.Session do
  def create(account_id) do
    session = %{account_id: account_id}
    with {:ok, jwt, _claims} <- Guardian.encode_and_sign(session, :access) do
      {:ok, jwt}
    end
  end

  def verify(jwt) do
    case Guardian.decode_and_verify(jwt) do
      {:ok, _claims} -> :ok
      {:error, _reason} -> {:error, :unauthorized}
    end
  end
end