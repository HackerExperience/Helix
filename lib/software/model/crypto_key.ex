# defmodule Helix.Software.Model.CryptoKey do

#   use Ecto.Schema

#   import Ecto.Changeset

#   alias Ecto.Changeset
#   alias Helix.Server.Model.Server
#   alias Helix.Software.Model.File
#   alias Helix.Software.Model.Storage

#   @type t :: %__MODULE__{
#     file_id: File.id,
#     target_file_id: File.id | nil,
#     target_server_id: Server.id,
#     file: term,
#     target_file: term
#   }

#   @default_path "/.keys"
#   @software_type :crypto_key

#   @primary_key false
#   schema "crypto_keys" do
#     field :file_id, File.ID,
#       primary_key: true

#     field :target_file_id, File.ID
#     field :target_server_id, Server.ID

#     belongs_to :file, File,
#       foreign_key: :file_id,
#       references: :file_id,
#       define_field: false

#     belongs_to :target_file, File,
#       foreign_key: :target_file_id,
#       references: :file_id,
#       define_field: false
#   end

#   @spec create(Storage.t, Server.idt, File.t) ::
#     Changeset.t
#   @doc """
#   Creates a key for `target_file` on `storage`.

#   `server_id` is the server that has `target_file` so we can inform the player
#   that the key is for a certain server in their hacked database
#   """
#   def create(storage = %Storage{}, server, target_file = %File{}) do
#     file = generate_file(storage)

#     %__MODULE__{}
#     |> cast(%{target_server_id: server}, [:target_server_id])
#     |> put_assoc(:target_file, target_file, required: true)
#     |> put_assoc(:file, file, required: true)
#     |> validate_required([:target_server_id])
#   end

#   defp generate_file(storage) do
#     params = %{
#       # FIXME: Use an apropriate
#       name: "Key #{Enum.random(1..100_000_000)}",
#       path: @default_path,
#       # REVIEW: Make keys actually have a size? If so we'd have to check if the
#       #   storage can store them tho
#       file_size: 1,
#       software_type: @software_type,
#     }

#     File.create(storage, params)
#   end

#   defmodule Query do
#     import Ecto.Query

#     alias Ecto.Queryable
#     alias Helix.Software.Model.CryptoKey
#     alias Helix.Software.Model.File
#     alias Helix.Software.Model.Storage

#     @spec by_storage(Queryable.t, Storage.idtb) ::
#       Queryable.t
#     def by_storage(query \\ CryptoKey, id) do
#       query
#       |> join(:inner, [k], f in File, k.file_id == f.file_id)
#       |> where([k, ..., f], f.storage_id == ^id)
#     end

#     @spec target_files_on_storage(Queryable.t, Storage.idtb) ::
#       Queryable.t
#     def target_files_on_storage(query \\ CryptoKey, id) do
#       query
#       |> join(:inner, [k], t in File, k.target_file_id == t.file_id)
#       |> where([k, ..., t], t.storage_id == ^id)
#     end

#     @spec target_file(Queryable.t, File.idtb) ::
#       Queryable.t
#     def target_file(query \\ CryptoKey, id),
#       do: where(query, [k], k.target_file_id == ^id)
#   end
# end
