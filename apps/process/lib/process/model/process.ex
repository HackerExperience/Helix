defmodule HELM.Process.Model.Process do
  use Ecto.Schema
  import Ecto.Changeset

  alias HELL.IPv6

  @primary_key {:process_id, EctoNetwork.INET, autogenerate: false}

  schema "processes" do
    timestamps
  end

  @creation_fields ~w()

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_primary_key()
  end

  defp put_primary_key(changeset) do
    ip = IPv6.generate([0x0005, 0x0000, 0x0000])

    changeset
    |> cast(%{process_id: ip}, ~w(process_id))
  end
end