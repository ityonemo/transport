# Transporter

## Abstraction API for TCP/TLS

Lets you select either TCP or TLS by swapping out mock-able
modules.

Use at your own risk!  For the moment, this module has not been
comprehensively reviewed by a security professional.  While many TLS
failure cases have been tested, the tests are not yet comprehensive.

Pull requests and reviews strongly welcome.

## Installation

The package can be installed by adding `transporter` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:transporter, "~> 0.1.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/transporter](https://hexdocs.pm/transporter).

