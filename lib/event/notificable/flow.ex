defmodule Helix.Event.Notificable.Flow do

  alias Helix.Notification.Model.Code, as: NotificationCode

  defmacro notification(do: block) do
    quote do

      defimpl Helix.Event.Notificable do
        @moduledoc false

        @class nil
        @code nil

        unquote(block)

        @class || raise "You must set a notification class with @class"
        @code || raise "You must set a notification code with @code"

        NotificationCode.code_exists?(@class, @code)
        || raise "Notification not found: #{inspect {@class, @code}}"

        @doc """
        Returns notification info (tuple with class and code)
        """
        def get_notification_info(_event) do
          {@class, @code}
        end

        # Fallbacks

        @doc false
        def extra_params(_) do
          %{}
        end
      end

    end
  end
end
