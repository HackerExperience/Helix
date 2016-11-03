defmodule HELL.TestHelper.IP do
  def valid_ipv6?(ip_str) do
    with \
      ip_chars <- String.to_charlist(ip_str),
      {:ok, _} <- :inet.parse_ipv6_address(ip_chars)
    do
      true
    else
      _ -> false
    end
  end
end