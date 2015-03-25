import ExPrintf
defmodule Utils do
	require Lager
	
	def stringify(nil, _) do
		nil
	end
	def stringify(number, decimals) do
		float = :erlang.float(number)
		sprintf("%.#{decimals}f",[float])
	end


	def timestampify(nil) do
		0
	end
	def timestampify(ticks) do
		ticks_from_epoch = ticks - 621355968000000000
		seconds_from_epoch = ticks_from_epoch/10000000
		trunc(seconds_from_epoch)
	end


	def decimalify(nil) do
		nil
	end
	def decimalify(number) when is_number(number) do
		Decimal.new(number)
	end
	def decimalify(_) do
		nil
	end

	def profily(action,func) do
		Lager.info String.capitalize(action)<>" started"
		{start_timer, _} = :erlang.statistics(:wall_clock)
		result = func.()
		{end_timer, _} = :erlang.statistics(:wall_clock)
		Lager.info String.capitalize(action)<>" ended in #{end_timer-start_timer} milliseconds"
		result
	end
end
