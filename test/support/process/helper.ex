defmodule Helix.Test.Process.Helper do

  alias Helix.Process.Model.Process
  alias Helix.Process.Repo, as: ProcessRepo

  def raw_get(process = %Process{}),
    do: raw_get(process.process_id)
  def raw_get(process_id),
    do: ProcessRepo.get(Process, process_id)

  def id,
    do: Process.ID.generate(%{}, {:process, :file_download})
end
