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
        {k, v = %{dlk: _, ulk: _}} when map_size(v) == 2 ->
          {k, v}
        {k, v = %{}} ->
          {k, Map.merge(%{dlk: 0, ulk: 0}, Map.take(v, [:dlk, :ulk]))}
      end)
      |> :maps.from_list()

    %{xs| net: net}
  end

  def replace_network_if_exists(r = %__MODULE__{}, n, dlk, ulk) when is_integer(dlk) and is_integer(ulk) do
    case r.net do
      %{^n => _} ->
        %{r| net: Map.put(r.net, n, %{dlk: dlk, ulk: ulk})}
      _ ->
        r
    end
  end

  def update_network_if_exists(r = %__MODULE__{}, n, f) do
    case r.net do
      %{^n => v} ->
        case f.(v) do
          # This is to ensure that the returned value complies with our contract
          # otherwise the error could happen later on the pipeline and just make
          # it harder to debug why it happened
          xs = %{dlk: x0, ulk: x1} when map_size(xs) == 2 and is_integer(x0) and is_integer(x1) ->
            %{r| net: Map.put(r.net, n, xs)}
        end
      _ ->
        r
    end
  end
end