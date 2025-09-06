defmodule RedisTest do
  use ExUnit.Case
  require Logger

  describe "Redis" do
    test "read and persist to Redis" do
      {:ok, conn1} = RedixConnection.connect(redis_container_ip())
      {:ok, conn2} = RedixConnection.connect("127.0.0.1")

      tasks = [
        Task.async(fn -> test_redis(conn1) end),
        Task.async(fn -> test_redis(conn2) end)
      ]

      results = Enum.map(tasks, fn task -> Task.await(task, 10000) end)

      Redix.stop(conn1)
      Redix.stop(conn2)

      assert Enum.any?(results, fn result -> result == :ok end),
             "At least one Redis connection test must succeed"
    end
  end

  defp test_redis(conn) do
    try do
      Logger.info("Testing Redis connection...")
      assert Redix.command(conn, ["PING"]) == {:ok, "PONG"}
      assert Redix.command(conn, ["SET", "mykey", "value"]) == {:ok, "OK"}
      assert Redix.command(conn, ["GET", "mykey"]) == {:ok, "value"}
      assert Redix.command(conn, ["DEL", "mykey"]) == {:ok, 1}
      :ok
    rescue
      e ->
        Logger.warn("Failed to test Redis connection: #{inspect(e)}")
        :error
    end
  end



  defp redis_container_id do
    {container, _} = System.cmd("docker", ["ps", "--filter", "name=support_redis", "--format", "{{.ID}}"])
    String.trim(container)
  end

  defp redis_container_ip do
    container_id = redis_container_id()
    redis_container_ip(container_id)
  end

  defp redis_container_ip(container) do
    IO.puts("redis_container_ip(#{container})")
    {ipaddr, _} = System.cmd("docker", ["inspect", "--format", "{{json .NetworkSettings.Networks.support_default.IPAddress}}", container])

    case Jason.decode(ipaddr) do
      {:ok, ip} -> ip
      _ -> "127.0.0.1"
    end
  end
end

defmodule RedixConnection do
  # Read more at: https://ubuntuask.com/blog/how-to-retry-connect-ampq-in-elixir

  require Logger

  @retry_interval 5000
  @max_retries 3
  @redis_port 6379


  def connect do
    connect_with_retry("127.0.0.1", @redis_port, 0)
  end

  def connect(host) do
    connect_with_retry(host, @redis_port, 0)
  end

  def connect(host, port) do
    connect_with_retry(host, port, 0)
  end


  defp connect_with_retry(host, port, retry_count) do
    case Redix.start_link(host: host, port: port) do
      {:ok, connection} ->
        Logger.info("Redis connection successful to #{host}:#{port}")
        {:ok, connection}

      {:error, _reason} when retry_count < @max_retries ->
        Logger.warn("Redis connection to #{host}:#{port} attempt #{retry_count} failed. Retrying in #{@retry_interval} milliseconds...")
        Process.sleep(@retry_interval)
        connect_with_retry(host, port, retry_count + 1)

      {:error, reason} ->
        Logger.error("Failed to connect to Redis at #{host}:#{port} after #{@max_retries} attempts. Reason: #{reason}")
        {:error, reason}
    end
  end
end
