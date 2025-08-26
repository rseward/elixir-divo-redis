defmodule RedisTest.MixProject do
  use Mix.Project

  def project do
    [
      app: :redis_test,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Configuration test paths to seperate uni
      test_paths: test_paths(Mix.env())
    ]
  end

  defp deps() do
  [
     {:divo, "~> 2.0.0", only: [:dev, :integration]},
     {:redix, "~> 1.0"}
  ]
  end

  defp test_paths(:integration) do
  [
    "test/integration"
  ]
  end

  defp test_paths(_) do
  [
    "test/unit"
  ]
  end

end
