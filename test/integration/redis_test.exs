defmodule RedisTest do
  use ExUnit.Case

  describe "Redis" do
    test "is available" do
      assert Redis.ping() == "PONG"
    end

    test "read and persist to Redis" do
      {:ok, :conn} = Redis.start_link(host: "localhost", port: 6379)
      assert Redis.set(:conn, "mykey", "value") == :ok
      assert Redis.get(:conn, "mykey") == "value"
      assert Redis.del(:conn, "mykey") == :ok
    end
  end
end
