defmodule TransportTest.ActiveClient do

  # implements an active: true server that is generic between TCP and SSL.

  use GenServer
  import Kernel, except: [send: 2]

  def start_link(transport, port, test_pid, opts \\ []) do
    state = %{transport: transport, port: port, test_pid: test_pid, opts: opts}
    GenServer.start_link(__MODULE__, state)
  end

  @localhost {127, 0, 0, 1}

  def init(data = %{transport: transport}) do
    transport_opts = [:binary, active: false]
    {:ok, socket} = transport.connect(@localhost, data.port, transport_opts)
    {:ok, upgraded} = transport.upgrade(socket, [active: true] ++ data.opts)
    {:ok, Map.merge(data, %{socket: upgraded, type: transport.type()})}
  end

  def send(server, data), do: GenServer.cast(server, {:send, data})

  def handle_cast({:send, data}, state = %{transport: transport}) do
    transport.send(state.socket, data)
    {:noreply, state}
  end

  def handle_info({type, _socket, data}, state = %{type: type}) do
    Kernel.send(state.test_pid, {:client, data})
    {:noreply, state}
  end

end
