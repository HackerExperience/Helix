defmodule Helix.Software.Model.FileTextTest do

  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias Helix.Software.Model.FileText

  alias Helix.Software.Factory

  defp generate_params do
    file = Factory.insert(:file)

    Factory.params_for(:file_text)
    |> Map.put(:file_id, file.file_id)
    |> Map.drop([:inserted_at, :updated_at])
  end

  test "creating file_text changeset only requires file_id and contents" do
    params = generate_params()
    cs1 = FileText.create_changeset(params)
    cs2 = FileText.create_changeset(%{})

    got = Enum.sort(Keyword.keys(cs2.errors))
    expected = Enum.sort([:file_id, :contents])

    assert expected == got
    assert cs1.valid?
  end

  test "updating file_text replaces its contents" do
    params = Map.take(generate_params(), [:contents])

    cs =
      generate_params()
      |> FileText.create_changeset()
      |> FileText.update_changeset(params)

    assert params.contents == Changeset.get_field(cs, :contents)
  end
end