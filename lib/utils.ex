import ExPrintf
defmodule Utils do

	
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
end
