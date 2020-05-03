# Transport

## Abstraction API for TCP/TLS

Lets you select either TCP or TLS by swapping out mock-able
modules.  Use at your own risk!  For the moment, this module has not been
comprehensively reviewed by a security professional.

## Installation

The package can be installed by adding `transport` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:transport, "~> 0.1.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/transport](https://hexdocs.pm/transport).

