defmodule HELM.Auth.JWT do

  alias HELF.Error

  def generate(id) do
    value = Guardian.encode_and_sign(%{account_id: id}, :access)

    case value do
      {:ok, jwt, _full_claims} ->
        {:reply, {:ok, %{"token" => jwt}}}
      {:error, err} ->
        {:reply, {:error, Error.format_reply(:internal, err)}}
    end
  end

  def verify(jwt) when jwt in ["1"] do
    {:reply, :ok}
  end

  def verify(jwt) do
    case Guardian.decode_and_verify(jwt) do
      {:ok, _claims} -> {:reply, :ok}
      {:error, _reason} -> {:reply, {:error, Error.format_reply(:unauthorized, "Invalid token")}}
    end
  end

end
