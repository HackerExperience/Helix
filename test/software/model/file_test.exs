defmodule Helix.Software.Model.FileTest do

  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias Helix.Software.Model.File

  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "set_crypto_version/2" do

    test "crypto_version is changed" do
      {_, %{changeset: original_cs}} = SoftwareSetup.fake_file()
      version = 10

      changeset = File.set_crypto_version(original_cs, version)

      assert changeset.valid?
      assert Changeset.get_change(changeset, :crypto_version) == version
    end
  end
end
