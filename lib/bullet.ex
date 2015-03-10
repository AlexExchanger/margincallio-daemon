defmodule Bullet do 
	use Jazz
	##
	##
	##
	def init(_transport, req, _opts, _active) do
		IO.puts "Init or reInit Bullet Connection"
		{:ok, req, %{}}
	end
	##
	##
	##
	def info(data,req,state) do
		IO.puts "Sending Message to Client"
		resp = case data do
			{:system,_} -> ""
			msg -> msg
		end
		{:reply,resp,req,state}
	end
	##
	##
	##
	def stream(data,req,state) do
		
		resp = case data do
			"ping" -> 
				new_state = state # otherwise new_state became nil
				"ping"
			json -> 
				msg = try do
    				JSON.decode!(json)
		        rescue
		            _ in JSON.SyntaxError -> nil
		        end
		        case msg do
		        	#==========================================================================
		        	nil ->
		        		new_state = state
		        		JSON.encode!(%{"status" => "error", "reason" => "unparsable json"})
	        		#==========================================================================
	        		%{"command"=> "subscribe_general", "currency" => currency} ->
	        			new_state = sub_general(state, currency)
	        			JSON.encode!(%{"status" => "success"})
    				#==========================================================================
    				%{"command"=> "subscribe_user","currency" => currency, "user_id" => user_id, "secret" => secret} ->
	        			if is_integer(user_id) != true do
	        				new_state = state
	        				JSON.encode!(%{"status" => "error", "reason" => "user_id should be integer"})
	        			else
	        				if check_secret(user_id, secret) do
	        					new_state = sub_user(state, currency, user_id)
	        					JSON.encode!(%{"status" => "success"})
	        				else
	        					new_state = state
	        					JSON.encode!(%{"status" => "error", "reason" => "incorrect channel"})
	        				end
        				end
    				#==========================================================================
    				_ -> 
    					new_state = state
    					JSON.encode!(%{"status" => "error", "reason" => "incorrect request"})
		        		
		        end
		end
		{:reply,resp,req,new_state}
	end
	##
	##
	##
	def terminate(_req, state) do
		unsub_all(state)
		IO.puts "Terminate"
	end
	##
	##
	##
	def sub(channel) do
		try do
			:gproc.reg({:p,:l,channel})
		rescue
			_ -> nil
		end
	end
	def unsub(channel) do
		try do
			:gproc.unreg({:p,:l,channel})
		rescue
			_ -> nil
		end
	end
	def pub(channel,msg) do
		:gproc.send({:p,:l,channel}, msg)
	end

	def check_secret(_user_id, _secret) do
		true
	end

	def sub_general(state,currency) do
		unsub_all(state)
		state_new = %{
			general: {:general, currency}
		}
		sub(state_new[:general])
		state_new
	end

	def sub_user(state, currency, user_id) do
		unsub_all(state)
		state_new = %{
			general: {:general, currency},
			user: {:user, user_id, currency}
		}
		sub(state_new[:general])
		sub(state_new[:user])
		sub({:user, user_id})
		state_new
	end

	def unsub_all(state) do
		IO.inspect [self,state]
		if state[:general] != nil do
			{:general, currency} = state[:general]
			unsub({:general, currency})
		end
		if state[:user] != nil do
			{:user, user_id, currency} = state[:user]
			unsub({:user, user_id, currency})
			unsub({:user, user_id})
		end
	end
end