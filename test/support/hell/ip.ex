defmodule HELL.TestHelper.IP do
  def ipv6?(ip_str) do
    {status, _} = ip_str |> String.to_charlist() |> :inet.parse_ipv6strict_address()
    status === :ok
  end
end