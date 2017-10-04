defmodule Helix.Test.Channel.Request.Helper do

  def mock_request(module, params, meta \\  %{}) do
    %{
      __struct__: module,
      params: params,
      meta: meta
    }
  end
end
