# Start Divo for the entire test suite
# This makes Divo stand up containers that last
# even if tests do not compile
Divo.Suite.start()

# Start unit tests after Divo starts
ExUnit.start()
