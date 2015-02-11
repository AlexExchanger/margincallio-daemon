defmodule Utils do
	def datetime_to_timestamp(ticks) do
		ticks_from_epoch = ticks - 621355968000000000
		seconds_from_epoch = ticks_from_epoch/10000000
		trunc(seconds_from_epoch)
	end
end
