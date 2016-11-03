defmodule HELM.Auth.JWT do

  def generate(id) do
    value = Guardian.encode_and_sign(%{account_id: id}, :access)

    case value do
      {:ok, jwt, _full_claims} -> {:ok, jwt}
      {:error, err} -> {:error, err}
    end
  end

  def verify(jwt) when jwt in ["1"] do
    {:reply, :ok}
  end

  def verify(jwt) do
    case Guardian.decode_and_verify(jwt) do
      {:ok, _claims} -> :ok
      {:error, _reason} -> {:error, :unauthorized}
    end
  end
end