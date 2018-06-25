defmodule Helix.Notification.Model.NotificationTest do

  use ExUnit.Case, async: true

  alias Helix.Notification.Model.Notification

  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Notification.Helper, as: NotificationHelper

  describe "Validator.validate_id/2" do
    test "accepts (and converts) when id is valid" do
      id1 = NotificationHelper.generate_id(:server)
      id2 = NotificationHelper.generate_id(:account)

      str_id1 = to_string(id1)
      str_id2 = to_string(id2)

      assert {:ok, id1} == Notification.Validator.validate_id(str_id1, [])
      assert {:ok, id2} == Notification.Validator.validate_id(str_id2, [])
    end

    test "rejects invalid id" do
      invalid_id1 = "abc"
      invalid_id2 = 1
      invalid_id3 = ServerHelper.id() |> to_string()

      assert :error == Notification.Validator.validate_id(invalid_id1, [])
      assert :error == Notification.Validator.validate_id(invalid_id2, [])
      assert :error == Notification.Validator.validate_id(invalid_id3, [])
    end
  end
end
