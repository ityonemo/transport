defmodule TransportTest.ActiveServer do

  # implements an active: true server that is generic between TCP and SSL.

  use GenServer
  import Kernel, except: [send: 2]

  def start_link(transport, test_pid, opts \\ []) do
    state = %{transport: transport, test_pid: test_pid, opts: opts}
    GenServer.start_link(__MODULE__, state)
  end

  def init(data = %{transport: transport}) do
    # TODO: make binary/not active the defaults
    transport_opts = [:binary, active: false]
    {:ok, socket} = transport.listen(0, transport_opts)
    {:ok, port}   = :inet.port(socket)
    Process.send_after(self(), {:accept, socket}, 0)
    {:ok, Map.merge(data, %{port: port, type: transport.type()})}
  end

  def port(server), do: GenServer.call(server, :port)

  def send(server, data), do: GenServer.cast(server, {:send, data})

  def handle_call(:port, _from, state) do
    {:reply, state.port, state}
  end

  def handle_cast({:send, data}, state = %{transport: transport}) do
    transport.send(state.socket, data)
    {:noreply, state}
  end

  def handle_info({:accept, accept_socket}, state = %{transport: transport}) do
    {:ok, socket} = transport.accept(accept_socket, 500)
    {:ok, upgraded} = transport.handshake(socket, [active: true] ++ state.opts)
    {:noreply, Map.put(state, :socket, upgraded)}
  end
  def handle_info({type, _socket, data}, state = %{type: type}) do
    Kernel.send(state.test_pid, {:server, data})
    {:noreply, state}
  end

end
