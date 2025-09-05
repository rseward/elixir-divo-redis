defmodule RedisTest do
  use ExUnit.Case

  describe "Redis" do
    test "is available" do
      :true
    end

    test "read and persist to Redis" do
      {:ok, conn} = RedixConnection.connect()
      assert Redix.command(conn,["PING"]) == {:ok, "PONG"}
      assert Redix.command(conn, ["SET", "mykey", "value"]) == {:ok, "OK"}
      assert Redix.command(conn, ["GET","mykey"]) == {:ok, "value"}
      assert Redix.command(conn, ["DEL", "mykey"] ) == {:ok, 1}
    end
  end
end

defmodule RedixConnection do
  # Read more at: https://ubuntuask.com/blog/how-to-retry-connect-ampq-in-elixir

  @retry_interval 5000
  @max_retries 3
  @redis_host "localhost"
  @redis_port 6379


  def connect do
    connect_with_retry(0)
  end

  defp connect_with_retry(retry_count) do
    case Redix.start_link(host: @redis_host, port: @redis_port) do
      {:ok, connection} ->
        Logger.info("Redis connection successful")
        {:ok, connection}

      {:error, _reason} when retry_count < @max_retries ->
        Logger.warn("Redis connection attempt #{retry_count} failed. Retrying in #{@retry_interval} milliseconds...")
        Process.sleep(@retry_interval)
        connect_with_retry(retry_count + 1)

      {:error, reason} ->
        Logger.error("Failed to connect to Redis after #{@max_retries} attempts. Reason: #{reason}")
        {:error, reason}
    end
  end
end
