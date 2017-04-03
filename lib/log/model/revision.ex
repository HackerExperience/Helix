defmodule Helix.Log.Model.Revision do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Log.Model.Log
  alias Helix.Log.Model.LogTouch

  import Ecto.Changeset

  @type t :: %__MODULE__{
    revision_id: PK.t,
    entity_id: PK.t,
    log_id: PK.t,
    message: String.t,
    forge_version: pos_integer | nil,
    log: Log.t
  }

  @type creation_params :: %{
    :entity_id => PK.t,
    :message => String.t,
    :log_id => PK.t,
    optional(:forge_version) => pos_integer | nil
  }

  @creation_fields ~w/entity_id message forge_version log_id/a

  @primary_key false
  @ecto_autogenerate {:revision_id, {PK, :pk_for, [:log_revision]}}
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

  @spec create_changeset(creation_params) ::Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:entity_id, :message])
    |> validate_number(:forge_version, greater_than: 0)
    |> prepare_changes(fn changeset ->
      # REVIEW: This callback is executed even if this is the revision that
      #   created the log entry

      message = get_field(changeset, :message)
      log_id = get_field(changeset, :log_id)
      entity_id = get_field(changeset, :entity_id)

      # The Log entity should be properly updated to reflect the lastest
      # revision
      changeset
      |> apply_changes()
      |> Ecto.assoc(:log)
      |> changeset.repo.update_all(set: [message: message])

      %LogTouch{}
      |> LogTouch.changeset(%{log_id: log_id, entity_id: entity_id})
      |> changeset.repo.insert(on_conflict: :nothing)

      changeset
    end)
  end
end
