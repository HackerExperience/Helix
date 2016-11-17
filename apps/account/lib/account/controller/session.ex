defmodule HELM.Account.Controller.Session do

  alias HELMF.Account.Model.Account, as: MdlAccount

  @spec create(MdlAccount.id) :: {:ok, String.t} | {:error, :unauthorized}
  def create(account_id) do
    session = %{account_id: account_id}
    with {:ok, jwt, _claims} <- Guardian.encode_and_sign(session, :access) do
      {:ok, jwt}
    else
      _ -> {:error, :unauthorized}
    end
  end

  @spec validate(String.t) :: boolean
  def validate(jwt) do
    case Guardian.decode_and_verify(jwt) do
      {:ok, _claims} -> true
      {:error, _reason} -> false
    end
  end
end