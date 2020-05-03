defmodule TransportTest.PassiveServer do

  # implements an active: false server that is generic between TCP and SSL.

  use GenServer
  import Kernel, except: [send: 2]

  def start_link(transport, test_pid, opts \\ []) do
    state = %{transport: transport, test_pid: test_pid, opts: opts}
    GenServer.start_link(__MODULE__, state)
  end

  def init(state = %{transport: transport}) do
    # TODO: make binary/not active the defaults
    {:ok, socket} = transport.listen(0)
    {:ok, port}   = :inet.port(socket)
    Process.send_after(self(), {:accept, socket}, 0)
    {:ok, Map.merge(state, %{port: port})}
  end

  # API
  def port(server), do: GenServer.call(server, :port)
  def handle_call(:port, _from, state), do: {:reply, state.port, state}

  def send(server, data), do: GenServer.cast(server, {:send, data})

  def handle_info({:accept, accept_socket}, state = %{transport: transport}) do
    {:ok, socket}  = transport.accept(accept_socket, 500)
    {:ok, upgrade} = transport.handshake(socket, state.opts)
    {:ok, data}    = transport.recv(upgrade, 0)
    Kernel.send(state.test_pid, {:server, data})
    {:noreply, Map.put(state, :socket, upgrade)}
  end

  # IMPLEMENTATIONS

  def handle_cast({:send, data}, state = %{transport: transport}) do
    transport.send(state.socket, data)
    {:noreply, state}
  end
end
