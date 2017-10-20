defmodule Helix.Test.Factor.Macros do

  defmacro get_fact(module, name, params, relay \\ quote(do: %{})) do
    quote do
      # {module}.fact_{name}({params}, {relay})
      apply(
        unquote(module),
        :"fact_#{unquote(name)}",
        [unquote(params), unquote(relay)]
      )
    end
  end

  defmacro assembly(
    module,
    params,
    relay \\ quote(do: %{}),
    fields \\ quote(do: :all))
  do
    quote do
      # {module}.assembly({params}, {relay}, {fields})
      apply(
        unquote(module),
        :assembly,
        [unquote(params), unquote(relay), unquote(fields)]
      )
    end
  end
end
