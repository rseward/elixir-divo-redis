# elixir-divo-redis

A simple project to demonstrate elixir unit tests integrated with a docker-compose.yaml file.

## Goals

- Create a test/support/docker-compose.yml file to start a container with redis running on the default port 6379 with a password of "redistest"
- Write an integration test to "use Divo" connect to redis
  - set a value
  - get the value
  - delete the value
 



