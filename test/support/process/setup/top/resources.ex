defmodule Helix.Test.Process.Setup.TOP.Resources do

  alias HELL.TestHelper.Random
  alias Helix.Test.Network.Helper, as: NetworkHelper

  @internet_id NetworkHelper.internet_id()

  def resources(opts \\ []) do
    network_id = Keyword.get(opts, :network_id, @internet_id)

    cpu = Random.number(min: 100, max: 20_000)
    ram = Random.number(min: 100, max: 20_000)
    dlk = Random.number(min: 100, max: 20_000)
    ulk = Random.number(min: 100, max: 20_000)

    total = %{
      cpu: cpu,
      ram: ram,
      ulk: Map.put(%{}, network_id, ulk),
      dlk: Map.put(%{}, network_id, dlk)
    }

    {total, %{}}
  end
end
