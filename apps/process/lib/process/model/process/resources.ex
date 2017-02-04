defmodule Helix.Process.Model.Process.Resources do

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
    cpu: non_neg_integer,
    ram: non_neg_integer,
    dlk: non_neg_integer,
    ulk: non_neg_integer
  }

  @type resourceable :: t | %{
    optional(:cpu) => non_neg_integer,
    optional(:ram) => non_neg_integer,
    optional(:dlk) => non_neg_integer,
    optional(:ulk) => non_neg_integer
  }

  @fields ~w/cpu ram dlk ulk/a

  @primary_key false
  embedded_schema do
    field :cpu, :integer, default: 0
    field :ram, :integer, default: 0
    field :dlk, :integer, default: 0
    field :ulk, :integer, default: 0
  end

  @spec changeset(t | Ecto.Changeset.t, resourceable) :: Ecto.Changeset.t
  def changeset(resource, params) do
    resource
    |> cast(params, [:cpu, :ram, :dlk, :ulk])
    |> validate_number(:cpu, greater_than_or_equal_to: 0)
    |> validate_number(:ram, greater_than_or_equal_to: 0)
    |> validate_number(:dlk, greater_than_or_equal_to: 0)
    |> validate_number(:ulk, greater_than_or_equal_to: 0)
  end

  @spec cast(resourceable) :: t
  def cast(input) do
    struct(__MODULE__, input)
  end

  @spec sum(t, resourceable) :: t
  def sum(res, b) do
    Map.merge(res, Map.take(b, @fields), fn _, v1, v2 -> v1 + v2 end)
  end

  @spec sub(t, resourceable) :: t
  def sub(res, b) do
    Map.merge(res, Map.take(b, @fields), fn _, v1, v2 -> v1 - v2 end)
  end

  @spec div(t, t | non_neg_integer) :: t
  @doc """
  Divides each resource from `x` by the value passed.

  Alternatively, another Resources struct can be passed as argument and the
  value of each resource will be divided by that struct's resources.

  To simplify and avoid errors, on the case of div'ing one struct by another, if
  the second value is 0 and the first is 0, 0 is set for that resource; if the
  second value is 0 and the first is not, it will be set to nil.

  ## Examples
      a = %Resources{cpu: 0}
      b = %Resources{cpu: 0}

      div(a, b)
      # %Resources{cpu: 0, ...}

      c = %Resources{cpu: 100}

      div(c, b)
      # %Resources{cpu: nil, ...}

      d = %Resources{cpu: 20}
      div(c, d)
      # %Resources{cpu: 5, ...}
  """
  def div(x = %__MODULE__{}, xs = %__MODULE__{}) do
    %__MODULE__{x|
      cpu: safe_div(x.cpu, xs.cpu),
      ram: safe_div(x.ram, xs.ram),
      dlk: safe_div(x.dlk, xs.dlk),
      ulk: safe_div(x.ulk, xs.ulk)}
  end

  def div(x = %__MODULE__{}, val) when is_integer(val) do
    %__MODULE__{x|
      cpu: Kernel.div(x.cpu, val),
      ram: Kernel.div(x.ram, val),
      dlk: Kernel.div(x.dlk, val),
      ulk: Kernel.div(x.ulk, val)}
  end

  @spec mul(t, non_neg_integer) :: t
  def mul(res, val) do
    %__MODULE__{res|
      cpu: res.cpu * val,
      ram: res.ram * val,
      dlk: res.dlk * val,
      ulk: res.ulk * val}
  end

  @spec min(t | nil, t | nil) :: t | nil
  def min(x = %__MODULE__{}, xs = %__MODULE__{}) do
    %__MODULE__{x|
      cpu: Kernel.min(x.cpu, xs.cpu),
      ram: Kernel.min(x.ram, xs.ram),
      dlk: Kernel.min(x.dlk, xs.dlk),
      ulk: Kernel.min(x.ulk, xs.ulk)}
  end

  def min(nil, b),
    do: b
  def min(a, nil),
    do: a

  @spec to_list(resourceable) :: [{:cpu | :ram | :dlk | :ulk, non_neg_integer}]
  def to_list(res) do
    res
    |> Map.take(@fields)
    |> :maps.to_list()
  end

  @spec compare(t, t) :: :eq | :lt | :gt | :divergent
  def compare(_a, _b) do
    # FIXME: this interface is pure garbage
    :eq
  end

  defp safe_div(x1, x2) when is_integer(x2) and x2 > 0,
    do: Kernel.div(x1, x2)
  defp safe_div(0, 0),
    do: 0
  defp safe_div(_, _),
    do: nil
end