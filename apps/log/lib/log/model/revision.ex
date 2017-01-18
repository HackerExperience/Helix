defmodule Helix.Log.Model.Revision do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Log.Model.Log

  import Ecto.Changeset

  @creation_fields ~w/entity_id message forge_version log_id/a

  @primary_key false
  schema "revisions" do
    field :revision_id, PK,
      primary_key: true


    field :entity_id, PK

    field :message, :string
    field :forge_version, :integer

    belongs_to :log, Log,
      foreign_key: :log_id,
      references: :log_id,
      type: PK
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:entity_id, :message, :log_id])
    |> validate_number(:forge_version, greater_than: 0)
    |> put_primary_key()
    |> prepare_changes(fn changeset ->
      # REVIEW: This callback is executed even if this is the revision that
      #   created the log entry

      message = get_field(changeset, :message)

      # The Log entity should be properly updated to reflect the lastest
      # revision
      changeset
      |> apply_changes()
      |> Ecto.assoc(:log)
      |> changeset.repo.update_all(set: [message: message])

      changeset
    end)
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    if get_field(changeset, :revision_id) do
      changeset
    else
      pk = PK.generate([0x0008, 0x0001, 0x0000])
      cast(changeset, %{revision_id: pk}, [:revision_id])
    end
  end
end