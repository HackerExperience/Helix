defmodule Helix.Test.Factor.FakeFactorClientOne do

  import Helix.Factor.Client

  get_factors(params) do
    factor Helix.Test.Factor.FakeFactorOne, params
    factor Helix.Test.Factor.FakeFactorTwo, params
  end
end

defmodule Helix.Test.Factor.FakeFactorClientTwo do

  import Helix.Factor.Client

  get_factors(params) do
    factor Helix.Test.Factor.FakeFactorOne, params, only: :sky_color
    factor Helix.Test.Factor.FakeFactorTwo, params, skip: :fact_three
  end
end
