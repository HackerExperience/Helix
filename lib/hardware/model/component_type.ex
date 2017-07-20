defmodule Helix.Hardware.Model.ComponentType do

  use Ecto.Schema

  alias HELL.Constant

  @type t :: %__MODULE__{
    component_type: Constant.t
  }

  @primary_key false
  schema "component_types" do
    field :component_type, Constant,
      primary_key: true
  end

  @doc false
  def possible_types do
    ~w/mobo cpu ram hdd nic/a
  end

  @doc false
  def type_implementations do
    %{
      cpu: Helix.Hardware.Model.Component.CPU,
      hdd: Helix.Hardware.Model.Component.HDD,
      ram: Helix.Hardware.Model.Component.RAM,
      nic: Helix.Hardware.Model.Component.NIC,
      mobo: Helix.Hardware.Model.Motherboard
    }
  end

  @spec type_implementation(Constant.t) ::
    module
    | nil
  def type_implementation(type),
    do: type_implementations()[type]
end
