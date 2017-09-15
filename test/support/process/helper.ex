defmodule Helix.Test.Process.Helper do

  alias Helix.Process.Model.Process
  alias Helix.Process.Repo, as: ProcessRepo

  def raw_get(process_id),
    do: ProcessRepo.get(Process, process_id)
end
