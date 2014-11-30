defmodule Bullet do 
	use Jazz
	##
	##
	##
	def init(_transport, req, _opts, _active) do
		IO.puts "Init or reInit Bullet Connection"
		new_state = %{channel: nil}
		sub({:general})
		{:ok, req, new_state}
	end
	##
	##
	##
	def info(data,req,state) do
		resp = case data do
			{:system,msg} -> ""
			msg -> msg
		end
		{:reply,resp,req,state}
	end
	##
	##
	##
	def stream(data,req,state) do
		resp = case data do
			"ping" -> "ping"
			json -> 
				msg = try do
    				JSON.decode!(json)
		        rescue
		            e in JSON.SyntaxError -> nil
		        end
		        resp = case msg do
		        	#==========================================================================
		        	nil ->
		        		JSON.encode!(%{"status" => "error", "reason" => "unparsable json"})
		        		new_state = state
	        		#==========================================================================
	        		%{"command"=> "subscribe", "channel" => channel, "user_id" => user_id} ->
	        			if is_integer(user_id) != true do
	        				new_state = state
	        				JSON.encode!(%{"status" => "error", "reason" => "user_id should be integer"})
	        			else
	        				if channel_valid?(channel, user_id) do
	        					sub({:user, user_id})
	        					new_state = %{state| channel: {:user,user_id}}
	        					JSON.encode!(%{"status" => "success"})
	        				else
	        					new_state = state
	        					JSON.encode!(%{"status" => "error", "reason" => "incorrect channel"})
	        				end
        				end
    				#==========================================================================
		        end
		end
		{:reply,resp,req,new_state}
	end
	##
	##
	##
	def terminate(req, state) do
		if state.channel != nil do
			unsub(state.channel)
		end
		unsub({:general})
		IO.puts "Terminate"
	end
	##
	##
	##
	def channel_valid?(channel, user_id) do
		str_id = to_string(user_id)
		str_channel = to_string(channel)
		bin_hash = :crypto.hmac(:sha256,Cfg.channel_key(), str_id)
        string_hash = Base.encode64(bin_hash)
        if string_hash == str_channel do
        	true
        else 
        	false
        end
	end
	##
	##
	##
	def sub(channel) do
		:gproc.reg({:p,:l,channel})
	end
	def unsub(channel) do
		:gproc.unreg({:p,:l,channel})
	end
	def pub(channel,msg) do
		:gproc.send({:p,:l,channel}, msg)
	end
end