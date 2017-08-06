defmodule Helix.Process.Internal.TOP.ServerResources do

  alias Ecto.Changeset
  alias Helix.Network.Model.Network
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Process.Resources

  defstruct [cpu: 0, ram: 0, net: %{}]

  @type t :: %__MODULE__{
    cpu: non_neg_integer,
    ram: non_neg_integer,
    net: %{Network.id => %{dlk: non_neg_integer, ulk: non_neg_integer}}
  }

  @type shares :: %{
    cpu: non_neg_integer,
    ram: non_neg_integer,
    net: %{Network.id => %{dlk: non_neg_integer, ulk: non_neg_integer}}
  }

  # TODO: FIXME: change symbols and fun names to things that make sense

  @spec cast(map) :: t
  def cast(params) do
    server_resources = struct(__MODULE__, params)

    # FIXME: This is hard to read, it basicaly ensures that all networks are
    #   just maps %{dlk: term, ulk: term}
    networks =
      server_resources.net
      |> Enum.map(fn
        {k, v = %{dlk: _, ulk: _}} when map_size(v) == 2 ->
          {Network.ID.cast!(k), v}
        {k, v = %{}} ->
          value = Map.merge(%{dlk: 0, ulk: 0}, Map.take(v, [:dlk, :ulk]))
          {Network.ID.cast!(k), value}
      end)
      |> :maps.from_list()

    %{server_resources| net: networks}
  end

  @spec replace_network_if_exists(t, Network.id, non_neg_integer, non_neg_integer) ::
    t
  def replace_network_if_exists(server_resources = %__MODULE__{}, net_id, dlk, ulk) when is_integer(dlk) and is_integer(ulk) do
    case server_resources.net do
      %{^net_id => _} ->
        updated_net = Map.put(
          server_resources.net,
          net_id,
          %{dlk: dlk, ulk: ulk})

        %{server_resources| net: updated_net}
      _ ->
        server_resources
    end
  end

  @spec update_network_if_exists(t, Network.id, ((map) -> map)) ::
    t
  def update_network_if_exists(server_resources = %__MODULE__{}, net_id, fun) do
    case server_resources.net do
      %{^net_id => value} ->
        case fun.(value) do
          # This is to ensure that the returned value complies with our contract
          # otherwise the error could happen later on the pipeline and just make
          # it harder to debug why it happened
          value = %{dlk: dlk, ulk: ulk}
          when map_size(value) == 2 and is_integer(dlk) and is_integer(ulk) ->
            updated_net = Map.put(server_resources.net, net_id, value)
            %{server_resources| net: updated_net}
        end
      _ ->
        server_resources
    end
  end

  @spec sub_from_process(t, Process.t | Changeset.t) ::
    {:ok, t}
    | {:error, {:resources, :lack, :cpu | :ram}}
    | {:error, {:resources, :lack, {:net, :dlk | :ulk, Network.id}}}
  def sub_from_process(server_resources = %__MODULE__{cpu: cpu, ram: ram, net: networks}, process) do
    process = Changeset.change(process)
    net_id = Changeset.get_field(process, :network_id)

    # If network doesn't exists and the process doesn't require network alloc,
    # it'll be returned as 0, and it's not a problem :)
    # If the network doesn't exists but the process requires it, the values
    # will be obviously negative
    rest =
      networks
      |> Map.get(net_id, %{})
      |> Map.merge(%{cpu: cpu, ram: ram})
      |> Resources.cast()
      |> Resources.sub(Changeset.get_field(process, :allocated))
      |> Map.take([:cpu, :ram, :dlk, :ulk])

    negative_resource = Enum.find(rest, fn {_, v} -> v < 0 end)
    case negative_resource do
      nil ->
        server_resources = replace_network_if_exists(
          %{server_resources| cpu: rest.cpu, ram: rest.ram},
          net_id,
          rest.dlk,
          rest.ulk)
        {:ok, server_resources}
      {:cpu, _} ->
        {:error, {:resources, :lack, :cpu}}
      {:ram, _} ->
        {:error, {:resources, :lack, :ram}}
      {resource_kind, _} when resource_kind in [:dlk, :ulk] ->
        {:error, {:resources, :lack, {:net, resource_kind, net_id}}}
    end
  end

  @spec sub_from_resources(t, Resources.t, Network.id) ::
    t
  @doc """
  Subtracts `resources` from `server_resources`.

  If network `net_id` exists for server resources `server_resources`, subtracts `resources`'s dlk and
  ulk from it
  """
  def sub_from_resources(server_resources = %__MODULE__{}, resources = %Resources{}, net_id) do
    %{server_resources|
      cpu: server_resources.cpu - resources.cpu,
      ram: server_resources.ram - resources.ram,
      net: case server_resources.net do
        networks = %{^net_id => %{dlk: dlk, ulk: ulk}} ->
          val = %{dlk: dlk - resources.dlk, ulk: ulk - resources.ulk}
          Map.put(networks, net_id, val)
        networks ->
          networks
      end
    }
  end

  @spec part_from_shares(t, shares) ::
    t
  @doc """
  Divides `x` by `shares` including dropping networks not requested by `shares`
  """
  def part_from_shares(server_resources = %__MODULE__{}, shares) do
    %__MODULE__{
      cpu: shares.cpu > 0 && div(server_resources.cpu, shares.cpu) || 0,
      ram: shares.ram > 0 && div(server_resources.ram, shares.ram) || 0,
      net:
        server_resources.net
        |> Map.take(Map.keys(shares.net))
        |> Enum.map(fn {net_id, %{dlk: dlk, ulk: ulk}} ->
          network_share = shares.net[net_id]
          divide_dlk_by = network_share.dlk
          divide_ulk_by = network_share.ulk

          updated_value = %{
            dlk: divide_dlk_by > 0 && div(dlk, divide_dlk_by) || 0,
            ulk: divide_ulk_by > 0 && div(ulk, divide_ulk_by) || 0
          }

          {net_id, updated_value}
        end)
        |> :maps.from_list()
    }
  end

  def sum_process(server_resources, process) do
    {allocated, network_id} = case process do
      %Process{} ->
        allocated = process.allocated
        network_id = process.network_id

        {allocated, network_id}
      %Changeset{} ->
        allocated = Changeset.get_field(process, :allocated)
        network_id = Changeset.get_field(process, :network_id)

        {allocated, network_id}
    end

    do_sum_process(server_resources, allocated, network_id)
  end

  defp do_sum_process(server_resources, allocated, network_id) do
    net = if network_id do
      net_alloc = Map.take(allocated, [:ulk, :dlk])
      sum_net_alloc = &Map.merge(&1, net_alloc, fn _, v1, v2 -> v1 + v2 end)
      Map.update(server_resources.net, network_id, net_alloc, sum_net_alloc)
    else
      server_resources.net
    end

    %{
      server_resources|
        cpu: server_resources.cpu + allocated.cpu,
        ram: server_resources.ram + allocated.ram,
        net: net
    }
  end

  @spec sum(t, t) ::
    t
  def sum(resources_a, resources_b) do
    net = Map.merge(resources_a.net, resources_b.net, fn
      _k, v1, v2 ->
        %{
          dlk: v1.dlk + v2.dlk,
          ulk: v1.ulk + v2.ulk
        }
    end)

    %__MODULE__{
      cpu: resources_a.cpu + resources_b.cpu,
      ram: resources_a.cpu + resources_b.cpu,
      net: net
    }
  end

  @spec sub(t, t) ::
    t
  def sub(resources_a, resources_b) do
    net = Map.merge(resources_a.net, resources_b.net, fn
      _k, v1, v2 ->
        %{
          dlk: v1.dlk - v2.dlk,
          ulk: v1.ulk - v2.ulk
        }
    end)

    %__MODULE__{
      cpu: resources_a.cpu - resources_b.cpu,
      ram: resources_a.cpu - resources_b.cpu,
      net: net
    }
  end

  @spec negatives(t) ::
    list
  def negatives(resources) do
    cpu = resources.cpu < 0 && [{:cpu, resources.cpu * -1}] || []
    ram = resources.ram < 0 && [{:ram, resources.ram * -1}] || []
    networks = Enum.reduce(resources.net, [], fn
      {net_id, values}, acc ->
        negative_net_res =
          values
          |> Enum.filter(fn {_, v} -> v < 0 end)
          |> Enum.map(fn {k, v} -> {k, net_id, v * -1} end)

        negative_net_res ++ acc
    end)

    cpu ++ ram ++ networks
  end

  @spec exceeds?(t, t) ::
    boolean
  @doc """
  Checks if any resource on `a` exceeds a resource on `b`

  In practice, seeing `a` and `b` as sets, this function will check if `a` is
  **not** a subset of `b`

  ## Examples

      iex> a = %{cpu: 10, ram: 10, net: %{"a::b" => %{ulk: 10, dlk: 10}}}
      %{}
      iex> b = %{cpu: 10, ram: 10, net: %{"a::b" => %{ulk: 10, dlk: 10}, "c::d" => %{ulk: 10, dlk: 10}}}
      %{}
      iex> exceeds?(a, b)
      false
      iex> exceeds?(%{a| cpu: 20}, b)
      true
      iex> exceeds?(%{a| net: %{"ffff::ffff" => %{ulk: 1, dlk: 1}}}, b)
      true
  """
  def exceeds?(a, b) do
    a.cpu > b.cpu
    or a.ram > b.ram
    or not MapSet.subset?(MapSet.new(Map.keys(a)), MapSet.new(Map.keys(b)))
    or Enum.any?(a.net, fn {net_id, a} ->
      b = b.net[net_id]

      a.ulk > b.ulk or a.dlk > b.dlk
    end)
  end
end
