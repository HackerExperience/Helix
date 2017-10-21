defmodule Helix.FactorTest do

  use ExUnit.Case, async: true

  import Helix.Test.Factor.Macros

  alias Helix.Test.Factor.FakeFactorOne
  alias Helix.Test.Factor.FakeFactorTwo

  describe "mocks" do
    test "FactorTestOne" do
      {factor, relay} = assembly(FakeFactorOne, %{})

      assert factor.sky_color == :blue
      assert factor.meaning_of_life == 42
      assert factor.dilma.partido == :pete
      assert factor.aecio.interesses == :pó
      assert factor.__struct__ == Helix.Test.Factor.FakeFactorOne
      assert factor.dilma.__struct__ == Helix.Test.Factor.FakeFactorOne.Dilma
      assert relay == %{}
    end

    test "FactorTestTwo" do
      {factor, relay} = assembly(FakeFactorTwo, %{})

      assert factor.lover.cake == :lie
      assert factor.fact_one
      assert factor.fact_two
      assert factor.fact_three

      assert relay.lol == :zor
      assert relay.wat == :taw
      assert relay.one == 1
      assert relay.two == 2
    end
  end

  describe "supports custom executable tasks" do
    test "all tasks" do
      {factor, relay} = FakeFactorTwo.assembly(%{}, %{}, :all)

      assert factor.fact_one
      assert factor.fact_two
      assert factor.fact_three
      assert factor.lover.cake == :lie
      refute Map.has_key?(relay, :detour)
    end

    test "custom task" do
      {factor, relay} = FakeFactorTwo.assembly(%{}, %{}, [:lover])

      refute Map.has_key?(relay, :fact_one)
      refute Map.has_key?(relay, :fact_two)
      refute Map.has_key?(relay, :fact_three)
      assert factor.lover.cake == :empty_lie
      assert relay.detour == true
    end
  end
end
