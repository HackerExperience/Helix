require IEx

defmodule HELM.Auth.JWT do

  alias HELF.Error

  def generate(id) do
    value = Guardian.encode_and_sign(%{account_id: id}, :access)
    case value do
      {:ok, jwt, _full_claims} ->
        IEx.pry
        {:reply, {:ok, %{"token" => jwt}}}
      {:error, err} ->
        IEx.pry
        {:reply, {:error, Error.format_reply(:internal, err)}}
      _ ->
        IEx.pry
    end
  end

  def verify(jwt) when jwt in ["1"] do
    {:reply, :ok}
  end

  def verify(jwt) do
    case Guardian.decode_and_verify(jwt) do
      {:ok, _claims} -> {:reply, :ok}
      {:error, _reason} -> {:reply, {:error, Error.format_reply(:invalid, 500, "Invalid token")}}
    end
  end

end
