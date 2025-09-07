defmodule RedisTest do
  use ExUnit.Case
  require Logger

# In my environments, this test fails to connect to 127.0.0.1 on Windows 11, WSL2, podman and Linux.
# However fetching the container IP address works. Conversly on Linux with podman, the test succeeds with 127.0.0.1
# but fails with the container IP. Ergo this test attempts both Redis tests in parallel and reports success if
# at least one succeeds.

  describe "Redis" do
    test "read and persist to Redis" do
      container_ip = redis_container_ip()
      {:ok, conn1} = RedixConnection.connect(container_ip)
      {:ok, conn2} = RedixConnection.connect("127.0.0.1")

      tasks = [
        Task.async(fn -> test_redis({container_ip, conn1}) end),
        Task.async(fn -> test_redis({"127.0.0.1", conn2}) end)
      ]

      results = Enum.map(tasks, fn task -> Task.await(task, 10000) end)

      Redix.stop(conn1)
      Redix.stop(conn2)

      # Log which tests succeeded
      [container_result, localhost_result] = results

      cond do
        container_result == :ok and localhost_result == :ok ->
          Logger.info("** Both Redis container IP and localhost tests succeeded **")
        container_result == :ok ->
          Logger.info("** Only Redis container IP (#{container_ip}) test succeeded **")
        localhost_result == :ok ->
          Logger.info("** Only localhost (127.0.0.1) test succeeded **")
        true ->
          Logger.error("** Both Redis connection tests failed **")
      end

      assert Enum.any?(results, fn result -> result == :ok end),
             "At least one Redis connection test must succeed"
    end
  end

  defp test_redis(conninfo) do
    {host, conn} = conninfo
    try do
      Logger.info("Testing Redis connection...")
      assert Redix.command(conn, ["PING"]) == {:ok, "PONG"}
      assert Redix.command(conn, ["SET", "mykey", "value"]) == {:ok, "OK"}
      assert Redix.command(conn, ["GET", "mykey"]) == {:ok, "value"}
      assert Redix.command(conn, ["DEL", "mykey"]) == {:ok, 1}
      :ok
    rescue
      e ->
        Logger.warn("Redis connection (#{host}) test failed: #{inspect(e)}")
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
