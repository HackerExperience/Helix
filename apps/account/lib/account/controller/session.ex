defmodule HELM.Account.Controller.Session do
  @type unauthorized :: {:error, :unauthorized}

  @spec create(account_id :: String.t) :: {:ok, String.t} | unauthorized
  def create(account_id) do
    session = %{account_id: account_id}
    with {:ok, jwt, _claims} <- Guardian.encode_and_sign(session, :access) do
      {:ok, jwt}
    else
      _ -> {:error, :unauthorized}
    end
  end

  @spec verify(jwt :: String.t) :: :ok | unauthorized
  def verify(jwt) do
    case Guardian.decode_and_verify(jwt) do
      {:ok, _claims} -> :ok
      {:error, _reason} -> {:error, :unauthorized}
    end
  end
end