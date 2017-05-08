defmodule Helix.Appsignal do

  # HACK: __using__ is expanded at compile-time. Since Appsignal is not
  #   available for dev/test environments, we have to delay the evaluation of
  #   the use macro. This macro exists for this reason
  defmacro phoenix_instrumentation do
    if Code.ensure_loaded?(Appsignal.Phoenix) do
      quote do
        use Appsignal.Phoenix
      end
    end
  end
end
