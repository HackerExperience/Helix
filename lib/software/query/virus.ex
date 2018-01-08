defmodule Helix.Software.Query.Virus do

  alias Helix.Software.Internal.Virus, as: VirusInternal

  defdelegate fetch(file_id),
    to: VirusInternal

  @doc """
  Returns a list of viruses on the given storage.
  """
  defdelegate list_by_storage(storage),
    to: VirusInternal

  @doc """
  Returns a list of viruses installed by the given entity.
  """
  defdelegate list_by_entity(entity),
    to: VirusInternal

  @doc """
  Returns a list of viruses installed by the given entity on the given storage.
  """
  defdelegate list_by_storage_and_entity(storage, entity),
    to: VirusInternal

  @doc """
  Checks whether the given entity has any virus installed on the given storage.
  """
  defdelegate entity_has_virus_on_storage?(entity, storage),
    to: VirusInternal

  @doc """
  Checks whether the given virus is active
  """
  defdelegate is_active?(file),
    to: VirusInternal
end
