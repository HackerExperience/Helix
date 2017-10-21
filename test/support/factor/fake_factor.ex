defmodule Helix.Test.Factor do

  import Helix.Factor

  factor FakeFactorOne do
    @moduledoc """
    This mock is a quite simple and straightforward usage of the Factor DSL.
    """

    @type factor :: term
    @type params :: term
    @type relay :: term

    factor_struct [:sky_color, :meaning_of_life, :dilma, :aecio]

    fact(:sky_color, _params, relay) do
      set_fact :blue
    end

    fact(:meaning_of_life, _params, relay) do
      set_fact 42
    end

    child [:dilma, :aecio]

    assembly(params, relay) do
      get_fact :sky_color
      get_fact :meaning_of_life
      get_fact :dilma
      get_fact :aecio
    end

    factor Dilma do

      @type factor :: term
      @type params :: term
      @type relay :: term

      factor_struct [:partido]

      fact(:partido, _params, relay) do
        set_fact :pete
      end

      assembly(params, relay) do
        get_fact :partido
      end
    end

    factor Aecio do

      @type factor :: term
      @type params :: term
      @type relay :: term

      factor_struct [:interesses]

      fact(:interesses, _params, relay) do
        set_fact :pó
      end

      assembly(params, relay) do
        get_fact :interesses
      end
    end
  end

  factor FakeFactorTwo do
    @moduledoc """
    This factor is designed to test `relay` and `facts` accumulation.
    """

    @type factor :: term
    @type params :: term
    @type relay :: term

    factor_struct [:fact_one, :fact_two, :fact_three, :lover]

    fact(:fact_one, _params, relay) do
      set_fact :ok, %{one: 1}
    end

    fact(:fact_two, _params, %{one: 1}) do
      set_fact :ok, %{two: 2}
    end

    fact(:fact_three, _params, %{wat: :taw}) do
      set_fact :ué, %{lol: :zor}
    end

    child :lover

    assembly(params) do
      get_fact :fact_one
      get_fact :fact_two
      get_fact :lover
      get_fact :fact_three
    end

    factor Lover do

      @type factor :: term
      @type params :: term
      @type relay :: term

      factor_struct [:cake, :notme]

      fact(:cake, _params, %{one: 1, two: 2}) do
        set_fact :lie, %{wat: :taw}
      end

      fact(:cake, _params, _relay) do
        set_fact :empty_lie, %{detour: true}
      end

      fact(:notme, _, _) do
        set_fact :ueh
      end

      assembly(%{}, relay) do
        get_fact :cake
        get_fact :notme
      end
    end
  end
end
