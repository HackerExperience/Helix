defmodule Helix.Software.Factor.FileTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Factor.Macros

  alias Helix.Software.Factor.File, as: FileFactor

  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "fact: size" do
    test "returns the expected fact" do
      {file, _} = SoftwareSetup.fake_file()

      {fact, _relay} = get_fact(FileFactor, :size, %{file: file})

      assert fact == file.file_size
    end
  end

  describe "fact: version" do
    test "returns the module versions correctly" do
      {file, _} = SoftwareSetup.fake_file(type: :cracker)

      {fact, _relay} = get_fact(FileFactor, :version, %{file: file})

      assert fact.bruteforce == file.modules.bruteforce.version
      assert fact.overflow == file.modules.overflow.version
    end

    test "returns empty when there are no modules" do
      {file, _} = SoftwareSetup.fake_file(type: :text)

      assert {fact, _relay} = get_fact(FileFactor, :version, %{file: file})

      assert fact == %{}
    end
  end

  describe "assembly" do
    test "returns all facts on assembly" do
      {file, _} = SoftwareSetup.fake_file()

      {facts, relay} = assembly(FileFactor, %{file: file})

      assert facts.size
      assert facts.version
      assert facts.__struct__ == FileFactor
      assert relay == %{}
    end
  end
end
