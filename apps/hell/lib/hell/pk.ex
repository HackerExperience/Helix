defmodule HELL.PK do

  @type t :: String.t

  @behaviour Ecto.Type

  # PK namespaces being used
  # 0x0000  *       *       -> [Account]
  # 0x0002  *       *       -> [Server]
  # 0x0003  *       *       -> [Hardware]
  #         0x0001  *         -> Component
  #         *       0x0000      -> Motherboard
  #         *       0x0001      -> HDD
  #         *       0x0002      -> CPU
  #         *       0x0003      -> RAM
  #         *       0x0004      -> NIC
  #         0x0002  *         -> MotherboardSlot
  #         0x0003  *         -> NetworkConnection
  # 0x0004  *       *       -> [Software]
  #         0x0000  *         -> File
  #         0x0001  *         -> Storage
  #         0x0002  *         -> ModuleRole
  # 0x0005  *       *       -> [Process]
  # *       0x0000  *         -> Process
  # 0x0006  *       *       -> [NPC]
  # 0x0007  *       *       -> [Clan]
  # 0x0008  *       *       -> [Log]
  #         0x0000  *         -> Log
  #         0x0001  *         -> Revision
  @spec generate([non_neg_integer]) :: t
  defdelegate generate(params),
    to: HELL.IPv6

  def type,
    do: :inet

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

  @spec parse_address(String.t) :: {:ok, Postgrex.INET.t} | :error
  defp parse_address(string) when is_binary(string) do
    string
    |> String.to_char_list()
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