defmodule TransportTest.PassiveClient do

  # implements an active: false client that is generic between TCP and SSL.

  use GenServer
  import Kernel, except: [send: 2]

  def start_link(transport, port, test_pid, opts \\ []) do
    state = %{transport: transport, port: port, test_pid: test_pid, opts: opts}
    GenServer.start_link(__MODULE__, state)
  end

  @localhost {127, 0, 0, 1}

  def init(state = %{transport: transport}) do
    transport_opts = [:binary, active: false]
    {:ok, socket} = transport.connect(@localhost, state.port, transport_opts)
    {:ok, upgrade} = transport.upgrade(socket, state.opts)

    {:ok, Map.put(state, :socket, upgrade)}
  end

  def send(server, msg), do: GenServer.cast(server, {:send, msg})

  def handle_cast({:send, msg}, state = %{transport: transport}) do
    transport.send(state.socket, msg)
    Process.send_after(self(), :recv, 0)
    {:noreply, state}
  end

  def handle_info(:recv, state = %{transport: transport}) do
    {:ok, data} = transport.recv(state.socket, 0)
    Kernel.send(state.test_pid, {:client, data})
    {:noreply, state}
  end
end
