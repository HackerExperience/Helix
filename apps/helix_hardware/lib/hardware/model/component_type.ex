defmodule Helix.Hardware.Model.ComponentType do

  use Ecto.Schema

  @type t :: %__MODULE__{
    component_type: String.t
  }

  @primary_key false
  schema "component_types" do
    field :component_type, :string,
      primary_key: true
  end

  @doc false
  def possible_types do
    ~w/mobo cpu ram hdd usb nic/
  end

  @doc false
  def type_implementations do
    %{
      "cpu" => Helix.Hardware.Model.Component.CPU,
      "hdd" => Helix.Hardware.Model.Component.HDD
    }
  end
end
