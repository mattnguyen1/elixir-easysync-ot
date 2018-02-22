defmodule ElixirEasysyncOt.MixProject do
	use Mix.Project

	def project do
		[
			app: :elixir_easysync_ot,
			version: "0.1.0",
			elixir: "~> 1.6",
			start_permanent: Mix.env() == :prod,
			deps: deps(),
			test_coverage: [tool: ExCoveralls],
			preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test, "coveralls.travis": :test]
		]
	end

	# Run "mix help compile.app" to learn about applications.
	def application do
		[
			extra_applications: [:logger]
		]
	end

	# Run "mix help deps" to learn about dependencies.
	defp deps do
		[
			{:excoveralls, github: "parroty/excoveralls"},
			{:ex_doc, "~> 0.16", only: :dev, runtime: false}
		]
	end
end
