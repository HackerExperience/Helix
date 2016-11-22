defmodule HELL.PK do

  @type t :: String.t | Postgrex.INET.t

  @spec generate([non_neg_integer]) :: t
  defdelegate generate(params),
    to: HELL.IPv6
end