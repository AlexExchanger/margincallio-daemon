defmodule Daemon do
	use Application
	def start do
		start(:normal, [])
	end
	def start(_type, _args) do
		dispatch = :cowboy_router.compile([{:_,
            [
        	{"/", :cowboy_static, {:file, "priv/index.html"}},
        	{"/bullet.js", :cowboy_static, {:file, "priv/bullet.js"}},
            {"/ws/[...]",      :bullet_handler, [{:handler, Bullet}]},
            ] }])

       {:ok, _} = :cowboy.start_http(:http, 100, [port: 8000], [env: [dispatch: dispatch]])

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
		result = :gen_tcp.connect({184,168,134,144}, 1340, [:binary, packet: :line, active: false])
		case result do
			{:ok, sock} -> recieve(sock)
			_ -> 
				:timer.sleep(5000)
				connect()
		end
	end
	def recieve(sock) do
		data = sock |> :gen_tcp.recv(0,1)
		case data do
			{:ok, msg} -> 
				IO.puts "New Message Recieved: "
				IO.puts msg
				GenServer.cast(:dispatcher, msg)
				recieve(sock)
			{:error, :timeout} -> 
				#IO.puts "timeout"
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
		IO.puts "JSON Decode Error"
		#log error
	end
	defp route(msg_raw) do
		msg = EngineMsg.raw_to_readable(msg_raw)
		if msg == nil do
			#log error
		else
			IO.inspect msg
			cond do
				Enum.member?(EngineMsg.system_types(),msg["type"]) ->
					GenServer.cast(:system_handler, msg)
				Enum.member?(EngineMsg.notify_types(),msg["type"]) -> 
					GenServer.cast(:notify_handler, msg)
			end
		end
		
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
	def handle_cast(msg_atom,state) do
		type = msg_atom["type"]
		msg = %{msg_atom| "type" => to_string(msg_atom["type"])}
		cond do
			Enum.member?([:NewPlaceLimit,:NewPlaceMarket,:NewPlaceInstant, :NewCancelOrder,:NewAddSL,:NewAddTP,:NewRemoveSL,:NewRemoveTP,], type) ->
				user_id = msg["user_id"]
				public_msg = msg |> Map.delete("user_id") |> Map.delete("func_call_id") |> Map.delete("func_call_source")
				Bullet.pub({:user,user_id},JSON.encode!(public_msg))
			Enum.member?([:NewAddTS, :NewRemoveTS], type) ->
				user_id = msg["user_id"]
				public_msg = msg |> Map.delete("user_id") |> Map.delete("func_call_id") |> Map.delete("func_call_source")
				Bullet.pub({:user,user_id},JSON.encode!(public_msg))
		end
		{:noreply, state}
	end
end

defmodule Daemon.NotifyHandler do
	use GenServer
	use Jazz
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
	def handle_cast(msg_atom,state) do
		type = msg_atom["type"]
		msg = %{msg_atom| "type" => to_string(msg_atom["type"])}
		case type do
			:NewTicker -> 
				Bullet.pub({:general},JSON.encode!(msg))
			:NewBalance -> 
				user_id = msg["user_id"]
				public_msg = Map.delete(msg,"user_id")
				Bullet.pub({:user,user_id},JSON.encode!(public_msg))
			:NewActiveBuyTop ->
				Bullet.pub({:general},JSON.encode!(msg))
			:NewActiveSellTop ->
				Bullet.pub({:general},JSON.encode!(msg))
			:NewAccountFee ->
				user_id = msg["user_id"]
				public_msg = Map.delete(msg,"user_id") |> Map.delete("func_call_id")
				Bullet.pub({:user,user_id},JSON.encode!(public_msg))
			:NewMarginLevel ->
				user_id = msg["user_id"]
				public_msg = Map.delete(msg,"user_id")
				Bullet.pub({:user,user_id},JSON.encode!(public_msg))
			:NewMarginCall ->
				user_id = msg["user_id"]
				public_msg = Map.delete(msg,"user_id")
				Bullet.pub({:user,user_id},JSON.encode!(public_msg))
		end
		{:noreply, state}
	end
end