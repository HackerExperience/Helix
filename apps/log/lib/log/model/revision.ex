defmodule Helix.Log.Model.Revision do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Log.Model.Log

  import Ecto.Changeset
  import Ecto.Query, only: [where: 3]

  @creation_fields ~w/player_id message forge_version log_id/a

  @primary_key false
  schema "revisions" do
    field :revision_id, PK,
      primary_key: true


    field :player_id, PK

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
    |> validate_required([:player_id, :message, :log_id])
    |> validate_number(:forge_version, greater_than: 0)
    |> put_primary_key()
    |> prepare_changes(fn changeset ->
      forge_version = get_field(changeset, :forge_version)

      if forge_version do
        log_id = get_field(changeset, :log_id)
        message = get_field(changeset, :message)

        # Log Revision are a pyramidal stack structure. So all and any log
        # revision that is "smaller" than this revision should be removed
        __MODULE__
        |> where([r], r.log_id == ^log_id)
        |> where([r], r.forge_version <= ^forge_version)
        |> changeset.repo.delete_all()

        # The Log entity should be properly updated to reflect the lastest
        # revision
        changeset
        |> apply_changes()
        |> Ecto.assoc(:log)
        |> changeset.repo.update_all(set: [message: message])
      end

      changeset
    end)
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    if get_field(changeset, :revision_id) do
      changeset
    else
      pk = PK.generate([])
      cast(changeset, %{revision_id: pk}, [:revision_id])
    end
  end
end