defmodule Helix.Process.Controller.TableOfProcesses.ServerResources do

  alias Ecto.Changeset
  alias Helix.Process.Model.Process, as: ProcessModel
  alias Helix.Process.Model.Process.Resources

  defstruct [cpu: 0, ram: 0, net: %{}]

  @type t :: %__MODULE__{
    cpu: non_neg_integer,
    ram: non_neg_integer,
    net: %{optional(HELL.PK.t) => %{dlk: non_neg_integer, ulk: non_neg_integer}}
  }

  @type shares :: %{
    cpu: non_neg_integer,
    ram: non_neg_integer,
    net: %{optional(HELL.PK.t) => %{dlk: non_neg_integer, ulk: non_neg_integer}}
  }

  # TODO: FIXME: change symbols and fun names to things that make sense

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

  @spec replace_network_if_exists(t, network_id :: HELL.PK.t, non_neg_integer, non_neg_integer) :: t
  def replace_network_if_exists(r = %__MODULE__{}, n, dlk, ulk) when is_integer(dlk) and is_integer(ulk) do
    case r.net do
      %{^n => _} ->
        %{r| net: Map.put(r.net, n, %{dlk: dlk, ulk: ulk})}
      _ ->
        r
    end
  end

  @spec update_network_if_exists(t, network_id :: HELL.PK.t, ((%{}) -> %{})) :: t
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

  @spec sub_from_process(t, ProcessModel.t) :: {:ok, t} | {:error, {:resources, :lack, :cpu | :ram | {:net, :dlk | :ulk, network_id :: HELL.PK.t}}}
  def sub_from_process(resources = %__MODULE__{cpu: c, ram: r, net: n}, process) do
    xs = Changeset.change(process)
    net_id = Changeset.get_field(xs, :network_id)

    rest =
      n
      |> Map.get(net_id, %{})
      |> Map.merge(%{cpu: c, ram: r})
      |> Resources.cast()
      |> Resources.sub(Changeset.get_field(xs, :allocated))
      # If network doesn't exists and the process doesn't require network alloc,
      # it'll be returned as 0, and it's not a problem :)
      # If the network doesn't exists but the process requires it, the values
      # will be obviously negative
      |> Map.take([:cpu, :ram, :dlk, :ulk])

    case Enum.find(rest, &(elem(&1, 1) < 0)) do
      nil ->
        r0 = %{resources| cpu: rest.cpu, ram: rest.ram}
        r1 = replace_network_if_exists(r0, net_id, rest.dlk, rest.ulk)
        {:ok, r1}
      {:cpu, _} ->
        {:error, {:resources, :lack, :cpu}}
      {:ram, _} ->
        {:error, {:resources, :lack, :ram}}
      {res, _} when res in [:dlk, :ulk] ->
        {:error, {:resources, :lack, {:net, res, net_id}}}
    end
  end

  @spec sub_from_resources(t, Resources.t, network_id :: HELL.PK.t) :: t
  @doc """
  Subtracts `res` from `server`.

  If network `n` exists for server resources `server`, subtracts `res`'s dlk and
  ulk from it
  """
  def sub_from_resources(server = %__MODULE__{}, res = %Resources{}, n) do
    %{server|
      cpu: server.cpu - res.cpu,
      ram: server.ram - res.ram,
      net: case server.net do
        z = %{^n => %{dlk: d1, ulk: u1}} ->
          Map.put(z, n, %{dlk: d1 - res.dlk, ulk: u1 - res.ulk})
        z ->
          z
      end
    }
  end

  @spec part_from_shares(t, shares) :: t
  @doc """
  Divides `x` by `shares` including dropping networks not requested by `shares`
  """
  def part_from_shares(x = %__MODULE__{}, shares) do
    %__MODULE__{
      cpu: shares.cpu > 0 && div(x.cpu, shares.cpu) || 0,
      ram: shares.ram > 0 && div(x.ram, shares.ram) || 0,
      net:
        x.net
        |> Map.take(Map.keys(shares.net))
        |> Enum.map(fn {k, %{dlk: d, ulk: u}} ->
          s = shares.net[k]
          d2 = s.dlk
          u2 = s.ulk

          v2 = %{
            dlk: d2 > 0 && div(d, d2) || 0,
            ulk: u2 > 0 && div(u, u2) || 0
          }

          {k, v2}
        end)
        |> :maps.from_list()
    }
  end
end