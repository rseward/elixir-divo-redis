defmodule RedisTest do
  use ExUnit.Case
  require Logger

  describe "Redis" do
    test "is available" do
      :true
    end

    @tag timeout: :infinity
    test "read and persist to Redis" do

      #Process.sleep(30*60*1000) # sleep for 30 minutes to keep the connection alive for testing purposes

      container_ip = redis_container_ip()
      Logger.info("Redis container IP: #{container_ip}")
      {:ok, conn} = RedixConnection.connect(container_ip)


      assert Redix.command(conn,["PING"]) == {:ok, "PONG"}
      assert Redix.command(conn, ["SET", "mykey", "value"]) == {:ok, "OK"}
      assert Redix.command(conn, ["GET","mykey"]) == {:ok, "value"}
      assert Redix.command(conn, ["DEL", "mykey"] ) == {:ok, 1}

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
    {ipaddr, _} = System.cmd("docker", ["inspect", "--format", "{{json .NetworkSettings.Networks.support_default.IPAddress}}", container])

    Jason.decode!(ipaddr)
  end
end

defmodule RedixConnection do
  # Read more at: https://ubuntuask.com/blog/how-to-retry-connect-ampq-in-elixir

  require Logger

  @retry_interval 5000
  @max_retries 3
  @redis_host "localhost"
  @redis_port 6379


  def connect do
    connect_with_retry(@redis_host, @redis_port, 0)
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
