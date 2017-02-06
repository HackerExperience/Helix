defmodule Helix.Process.Controller.TableOfProcesses.ServerResources do

  defstruct [cpu: 0, ram: 0, net: %{}]

  @type t :: %__MODULE__{
    cpu: non_neg_integer,
    ram: non_neg_integer,
    net: %{optional(HELL.PK.t) => %{dlk: non_neg_integer, ulk: non_neg_integer}}
  }

  def cast(resources) do
    xs = struct(__MODULE__, resources)
    net =
      xs.net
      |> Enum.map(fn
        {k, v = %{dlk: _, ulk: _}} ->
          {k, v}
        {k, v = %{}} ->
          {k, Map.merge(%{dlk: 0, ulk: 0}, Map.take(v, [:dlk, :ulk]))}
      end)
      |> :maps.from_list()

    %{xs| net: net}
  end
end