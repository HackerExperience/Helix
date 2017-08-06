defmodule HELL.PK do

  @behaviour Ecto.Type

  @type t :: String.t

  @spec pk_for(atom) ::
    t
  defdelegate pk_for(atom),
    to: HELL.PK.Header

  def type,
    do: :inet

  def cast(id_struct = %_{id: _}),
    do: {:ok, to_string(id_struct)}
  def cast(ipv6 = %Postgrex.INET{}),
    do: {:ok, to_string(ipv6)}
  def cast(string) when is_binary(string) do
    case parse_address(string) do
      {:ok, _} ->
        {:ok, string}
      _ ->
        :error
    end
  end

  def cast(_) do
    :error
  end

  def load(ipv6 = %Postgrex.INET{}),
    do: {:ok, to_string(ipv6)}
  def load(_),
    do: :error

  def dump(ipv6 = %Postgrex.INET{}),
    do: {:ok, ipv6}
  def dump(string) when is_binary(string),
    do: parse_address(string)
  def dump(_),
    do: :error

  @spec parse_address(t) ::
    {:ok, Postgrex.INET.t}
    | :error
  defp parse_address(string) when is_binary(string) do
    string
    |> String.to_charlist()
    |> :inet.parse_ipv6strict_address()
    |> case do
      {:ok, address_tuple} ->
        {:ok, %Postgrex.INET{address: address_tuple}}
      {:error, :einval} ->
        :error
    end
  end
end

defimpl String.Chars, for: Postgrex.INET do
  def to_string(%Postgrex.INET{address: address_tuple}) do
    address_tuple
    |> :inet.ntoa()
    |> List.to_string()
  end
end
