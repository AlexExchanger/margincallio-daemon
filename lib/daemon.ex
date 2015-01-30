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
		result = :gen_tcp.connect({184,168,134,144}, 1350, [:binary, packet: :line, active: false])
		# result = :gen_tcp.connect({127,0,0,1}, 5679, [:binary, packet: 2, active: false])
		case result do
			{:ok, sock} -> 
				IO.puts "Connection Success"
				recieve(sock)
			_ -> 
				IO.puts "Connection Error"
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
	use Jazz
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
			Enum.member?([:NewPlaceLimit,:NewPlaceMarket,:NewPlaceInstant,:NewAddSL,:NewAddTP, :NewAddTS, :NewForcedLiquidation, :NewExecTS, :NewExecTP, :NewExecSL], type) ->
				offset_db = if msg["offset"] === nil do
					nil
				else
					Decimal.new(msg["offset"])
				end
				order = %Order{
					id: msg["order_id"],
					userId: msg["user_id"],
					size: Decimal.new(msg["amount"]),
					offset: offset_db,
					price: Decimal.new(msg["rate"]),
					createdAt: msg["datetime"],
					updatedAt: msg["datetime"],
					status: "accepted",
					type: EngineMsg.type_to_order_type(type),
					side: msg["side"]!=0, #hack to make boolean
				}
				Repo.insert(order)
				public_msg = %{
					"type" => msg["type"],
					"order_id" => msg["order_id"],
					"rate" => msg["rate"],
					"amount" => msg["amount"],
					"side" => msg["side"],
					"datetime" => msg["datetime"],
					"status" => "accepted",
					"offset" => msg["offset"],
				}
				Bullet.pub({:user, msg["user_id"]}, JSON.encode!(public_msg))

			type == :NewOrderStatus ->
				order = Order.get_by_id(msg["order_id"])
				status = if msg["status"]==0 do
					"partialFilled"
				else 
					"filled"
				end
				new_order = %Order{order| status: status}
				Repo.update(new_order)
				user_msg = %{
					"type" => msg["type"],
					"order_id" => msg["order_id"],
					"status" => status,
					"datetime" => msg["datetime"],
				}
				Bullet.pub({:user, msg["user_id"]}, JSON.encode!(user_msg))


			Enum.member?([:NewRemoveSL, :NewRemoveTP, :NewRemoveTS, :NewCancelOrder], type) ->
				order = Order.get_by_id(msg["order_id"])
				order_cancelled = %Order{order| status: "cancelled"}
				Repo.update(order_cancelled)
				public_msg = %{
					"type" => msg["type"],
					"order_id" => msg["order_id"],
					"status" => "cancelled",
					"datetime" => msg["datetime"],
				}
				Bullet.pub({:user, msg["user_id"]}, JSON.encode!(public_msg))

			type == :NewTrade ->
				deal = %Deal{
					id: msg["trade_id"],
					size: Decimal.new(msg["amount"]),
					price: Decimal.new(msg["rate"]),
					orderBuyId: msg["buy_order_id"],
					orderSellId: msg["sell_order_id"],
					createdAt: msg["datetime"],
					userBuyId: msg["buyer_user_id"],
					userSellId: msg["seller_user_id"],
					buyerFee: Decimal.new(msg["buyer_fee"]),
					sellerFee: Decimal.new(msg["seller_fee"]),
					side: msg["side"]!=0, #hack to make boolean
				}
				Repo.insert(deal)
				buyer_msg =%{
					"type"  => msg["type"],
					"trade_id"=> msg["trade_id"],
					"amount"=> msg["amount"],
					"rate"=> msg["rate"],
					"order_id"=> msg["buy_order_id"],
					"datetime"=> msg["datetime"],
					"fee"=> msg["buyer_fee"],
					"side"=> msg["side"],
				}
				buyer_user_id = msg["buyer_user_id"]
				Bullet.pub({:user, buyer_user_id}, JSON.encode!(buyer_msg))

				seller_msg =%{
					"type"  => msg["type"],
					"trade_id"=> msg["trade_id"],
					"amount"=> msg["amount"],
					"rate"=> msg["rate"],
					"order_id"=> msg["sell_order_id"],
					"datetime"=> msg["datetime"],
					"fee"=> msg["seller_fee"],
					"side"=> msg["side"],
				}
				seller_user_id = msg["seller_user_id"]
				Bullet.pub({:user, seller_user_id}, JSON.encode!(seller_msg))

				public_msg = %{
					"type"  => msg["type"]<>"Public", # not forget to spec type newTradePublic
					"trade_id"=> msg["trade_id"],
					"amount"=> msg["amount"],
					"rate"=> msg["rate"],
					"datetime"=> msg["datetime"],
					"side"=> msg["side"],
				}
				Bullet.pub({:general},JSON.encode!(public_msg))
			type == :NewMarketStatus ->
				status = case msg["status"] do
					0 -> "Closed"
					1 -> "Opened"
				end 
				log = %DBLog{
					action: "newMarketStatus",
					data: status,
					createdAt: msg["datetime"],
				}
				Repo.insert(log)
				public_msg = %{
					"type" => msg["type"],
					"status" => status,
					"datetime" => msg["datetime"],
				}
				Bullet.pub({:general}, JSON.encode!(public_msg))
			type == :NewFixRestart ->
				status = if msg["status_code"] == 29 do
					"ErrorFixRestartFailed"
				else
					"Success"
				end
				log = %DBLog{
					action: "fixRestart",
					data: status,
					createdAt: msg["datetime"],
				}
				Repo.insert(log)
				public_msg = %{
					"type" => msg["type"],
					"status" => status,
					"datetime" => msg["datetime"],
				}
				Bullet.pub({:general}, JSON.encode!(public_msg))
			type == :NewSnapshotOperation -> 
				status = case msg["status_code"] do
					0 -> "Success"
					37 -> "ErrorSnapshotBackupFailed"
					38 -> "ErrorSnapshotRestoreFailed"
				end
				action = case msg["op_code"] do
					0 -> "backupMaster"
					1 -> "restoreMaster"
					2 -> "restoreSlave"
				end
				log = %DBLog{
					action: action,
					data: status,
					createdAt: msg["datetime"],
				}
				Repo.insert(log)
				public_msg = %{
					"type" => msg["type"],
					"action" => action,
					"status" => status,
					"datetime" => msg["datetime"],
				}
				Bullet.pub({:general}, JSON.encode!(public_msg))
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