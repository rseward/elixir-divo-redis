build:
	mix deps.get
	mix compile

tests:
	mix test.integration