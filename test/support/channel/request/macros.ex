defmodule Helix.Test.Channel.Request.Macros do

  defmacro replace_param(request, key, value) do
    quote do
      new_params =
        Map.replace(unquote(request).params, unquote(key), unquote(value))

      var!(request) = %{unquote(request)| params: new_params}
    end
  end
end
