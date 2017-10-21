defmodule Helix.Factor.ClientTest do

  use ExUnit.Case, async: true

  alias Helix.Factor.Client, as: FactorClient

  alias Helix.Test.Factor.FakeFactorClientOne
  alias Helix.Test.Factor.FakeFactorClientTwo
  alias Helix.Test.Factor.FakeFactorOne
  alias Helix.Test.Factor.FakeFactorTwo

  describe "mock" do
    test "FakeFactorClientOne" do
      # FakeFactorClientOne gets *all* facts from FakeFactorOne and Two.
      factors = FakeFactorClientOne.get_factors(%{})

      # Returned the actual struct of the underlying factors
      assert factors.fakefactorone.__struct__ == FakeFactorOne
      assert factors.fakefactortwo.__struct__ == FakeFactorTwo
    end

    test "FakeFactorClientTwo" do
      # FakeFactorClientTwo will get facts from both FakeFactorOne and Two,
      # but only the `meaning_of_life` fact from One, and skipping `fact_three`
      # from Two
      factors = FakeFactorClientTwo.get_factors(%{})

      # Facts from FakeFactorOne
      assert factors.fakefactorone.sky_color
      refute Map.has_key?(factors.fakefactorone, :meaning_of_life)

      # Facts from FakeFactorTwo
      assert factors.fakefactortwo.fact_one
      assert factors.fakefactortwo.fact_two
      assert factors.fakefactortwo.lover
      refute Map.has_key?(factors.fakefactortwo, :fact_three)

      # Returned factor is a map with multiple factors, it's not a struct.
      refute Map.has_key?(factors, :__struct__)
    end
  end

  describe "FactorClientUtils.build_executable" do
    test "returns :all if no opts were specified" do
      assert :all == FactorClient.Utils.build_executable([], [:a, :b, :c])
    end

    test "filters out facts not listed on `only`" do
      all_facts = [:a, :b, :c, :d]
      only1 = :a
      only2 = [:b, :d]
      only3 = all_facts
      only4 = [:z]

      assert [only1] ==
        FactorClient.Utils.build_executable([only: only1], all_facts)

      assert only2 ==
        FactorClient.Utils.build_executable([only: only2], all_facts)

      assert :all ==
        FactorClient.Utils.build_executable([only: only3], all_facts)

      # Can't filter something that does not exist.
      assert_raise RuntimeError, fn ->
        FactorClient.Utils.build_executable([only: only4], all_facts)
      end
    end

    test "filters out facts listed on `skip`" do
      all_facts = [:a, :b, :c, :d]
      skip1 = :a
      skip2 = [:b, :c, :d]
      skip3 = all_facts
      skip4 = [:z]

      result1 = FactorClient.Utils.build_executable([skip: skip1], all_facts)
      assert result1 == all_facts -- [skip1]

      result2 = FactorClient.Utils.build_executable([skip: skip2], all_facts)
      assert result2 == all_facts -- skip2

      # Can't skip everything
      assert_raise RuntimeError, fn ->
        FactorClient.Utils.build_executable([skip: skip3], all_facts)
      end

      # Can't skip something that does not exist.
      assert_raise RuntimeError, fn ->
        FactorClient.Utils.build_executable([skip: skip4], all_facts)
      end
    end

    test "both `only` and `skip` working together" do
      all_facts = [:a, :b, :c, :d]

      # This really makes no sense
      only = [:b, :d]
      skip = :d

      assert [:b] ==
        FactorClient.Utils.build_executable([skip: skip, only: only], all_facts)
    end
  end
end
