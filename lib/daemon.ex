defmodule Daemon do
	use Application
	def start do
		start(:normal, [])
	end
	def start(_type, _args) do
		Daemon.Supervisor.start_link
	end
	
end

defmodule Daemon.Supervisor do
	use Supervisor

	def start_link do
		Supervisor.start_link(__MODULE__, :ok)
	end

	def init(:ok) do
		children = [
			worker(Repo, []),
			worker(Daemon.SystemHandler, [[name: :system_handler]]),
			worker(Daemon.NotifyHandler, [[name: :notify_handler]]),
			worker(Daemon.Dispatcher, [[name: :dispatcher]]),
			worker(Task,[Daemon.Reciever, :connect,[]]),
		]
		supervise(children, strategy: :one_for_one)
	end
end

defmodule Daemon.Reciever do
	def connect() do
		IO.puts "Connection"
		result = :gen_tcp.connect({127,0,0,1}, 5679, [:binary, packet: 2, active: false])
		case result do
			{:ok, sock} -> recieve(sock)
			_ -> connect()
		end
	end
	def recieve(sock) do
		data = sock |> :gen_tcp.recv(0,1)
		case data do
			{:ok, msg} -> 
				IO.puts "New Message Recieved"
				GenServer.cast(:dispatcher, msg)
				recieve(sock)
			{:error, :timeout} -> 
				IO.puts "timeout"
				recieve(sock)
			{:error, _} ->
				IO.puts "Socket Error"
				connect()
		end
	end
	
end

defmodule Daemon.Dispatcher do
	use GenServer
	use Jazz
	def start_link(arg) do
		GenServer.start_link(__MODULE__,:ok, arg)
	end
	def init(:ok) do
		IO.puts "Dispatcher Started"
		{:ok, []}
	end
	def handle_call(msg,_from,state) do
		{:noreply, state}
	end
	def handle_info(msg,state) do
		{:noreply, state}
	end
	def handle_cast(json_msg,state) do
		msg = try do
            JSON.decode!(json_msg)
        rescue
            e in JSON.SyntaxError -> nil
        end
        route(msg)
		{:noreply, state}
	end
	defp route(nil) do
		#log error
	end
	defp route(%{type: "system"}=msg) do
		GenServer.cast(:system_handler, msg)
	end
	defp route(%{type: "notify"}=msg) do
		GenServer.cast(:notify_handler, msg)
	end
	defp route(_) do
		#log error
	end
end

defmodule Daemon.SystemHandler do
	use GenServer
	def start_link(arg) do
		GenServer.start_link(__MODULE__,:ok, arg)
	end
	def init(:ok) do
		IO.puts "System Handler Started"
		{:ok, []}
	end
	def handle_call(msg,_from,state) do
		{:noreply, state}
	end
	def handle_info(msg,state) do
		{:noreply, state}
	end
	def handle_cast(msg,state) do
		#DB Call
		{:noreply, state}
	end
end

defmodule Daemon.NotifyHandler do
	use GenServer
	def start_link(arg) do
		GenServer.start_link(__MODULE__,:ok, arg)
	end
	def init(:ok) do
		IO.puts "Notification Handler Started"
		{:ok, []}
	end
	def handle_call(msg,_from,state) do
		{:noreply, state}
	end
	def handle_info(msg,state) do
		{:noreply, state}
	end
	def handle_cast(msg,state) do
		#Realplexor Cast
		{:noreply, state}
	end
end