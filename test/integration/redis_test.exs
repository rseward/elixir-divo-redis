defmodule RedisTest do
  use ExUnit.Case

  describe "Redis" do
    test "is available" do
      :true
    end

    test "read and persist to Redis" do
      {:ok, conn} = Redix.start_link(host: "localhost", port: 6379)
      assert Redix.command(conn,["PING"]) == {:ok, "PONG"}
      assert Redix.command(conn, ["SET", "mykey", "value"]) == {:ok, "OK"}
      assert Redix.command(conn, ["GET","mykey"]) == {:ok, "value"}
      assert Redix.command(conn, ["DEL", "mykey"] ) == {:ok, 1}
    end
  end
end
