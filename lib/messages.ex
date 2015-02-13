defmodule EngineMsg do
	def type_to_atom(type) do
		case type do
			0 -> :NewBalance 
			1 -> :NewTicker 
			2 -> :NewActiveBuyTop 
			3 -> :NewActiveSellTop 
			4 -> :NewPlaceLimit 
			5 -> :NewPlaceMarket 
			6 -> :NewPlaceInstant 
			7 -> :NewTrade 
			8 -> :NewCancelOrder 
			9 -> :NewAddSL 
			10 -> :NewAddTP 
			11 -> :NewAddTS 
			12 -> :NewRemoveSL 
			13 -> :NewRemoveTP 
			14 -> :NewRemoveTS 
			15 -> :NewAccountFee 
			16 -> :NewMarginInfo
			17 -> :NewMarginCall 
			18 -> :NewForcedLiquidation 
			19 -> :NewExecSL 
			20 -> :NewExecTP 
			21 -> :NewExecTS 
			22 -> :NewFixRestart
			23 -> :NewOrderStatus
			24 -> :NewMarketStatus
			25 -> :NewSnapshotOperation
			_ -> nil
		end
	end

	def system_types do
		[
			:NewPlaceLimit, 
			:NewPlaceMarket, 
			:NewPlaceInstant, 
			:NewTrade, 
			:NewCancelOrder, 
			:NewAddSL, 
			:NewAddTP, 
			:NewAddTS, 
			:NewRemoveSL, 
			:NewRemoveTP, 
			:NewRemoveTS, 
			:NewForcedLiquidation, 
			:NewExecSL, 
			:NewExecTP, 
			:NewExecTS,
			:NewFixRestart,
			:NewOrderStatus,
			:NewMarketStatus,
			:NewSnapshotOperation ,
		]
	end

	def notify_types do

		[
			:NewBalance, 
			:NewTicker, 
			:NewActiveBuyTop, 
			:NewActiveSellTop, 
			:NewAccountFee,
			:NewMarginLevel,
			:NewMarginCall,
		]
	end

	def type_to_order_type(type) do
		case type do 
			:NewPlaceLimit -> "LIMIT"
			:NewPlaceMarket -> "MARKET"
			:NewPlaceInstant -> "INSTANT"
			:NewForcedLiquidation -> "MARKET"
			:NewAddSL -> "STOPLOSS"
			:NewAddTP -> "TAKEPROFIT"
			:NewAddTS -> "TRAILINGSTOP"
			:NewRemoveSL -> "STOPLOSS"
			:NewRemoveTP -> "TAKEPROFIT"
			:NewRemoveTS -> "TRAILINGSTOP"
			:NewExecSL -> "MARKET"
			:NewExecTP -> "MARKET"
			:NewExecTS -> "MARKET"
		end
	end

	def raw_to_readable(msg_raw) do

		type = type_to_atom(msg_raw["0"])
		if type == nil do
			nil
		else
			cond do
				type == :NewBalance ->
					%{
						"type" => type,
						"user_id" => msg_raw["1"],
						"available_funds_1" => msg_raw["2"],
						"blocked_funds_1" => msg_raw["3"],
						"available_funds_2" => msg_raw["4"],
						"blocked_funds_2" => msg_raw["5"],
						"datetime" => msg_raw["6"],
					}
				type == :NewTicker ->
					%{
						"type" => type,
						"bid_price" => msg_raw["1"],
						"ask_price" => msg_raw["2"],
						"datetime" => msg_raw["3"],
					}
				type == :NewActiveBuyTop ->
					%{
						"type" => type,
						"buy_levels" => msg_raw["1"],
						"datetime" => msg_raw["2"],
					}
				type == :NewActiveSellTop ->
					%{
						"type" => type,
						"sell_levels" => msg_raw["1"],
						"datetime" => msg_raw["2"],
					}
				Enum.member?([:NewPlaceLimit,:NewPlaceMarket,:NewPlaceInstant, :NewCancelOrder,:NewAddSL,:NewAddTP,:NewRemoveSL,:NewRemoveTP,], type) ->
					%{
						"type" => type,
						"func_call_id" => msg_raw["1"],
						"func_call_source" => msg_raw["2"],
						"order_id" => msg_raw["3"],
						"user_id" => msg_raw["4"],
						"side" => msg_raw["5"],
						"amount" => msg_raw["6"],
						"rate" => msg_raw["7"],
						"datetime" => msg_raw["8"],
					}
				Enum.member?([:NewAddTS, :NewRemoveTS], type) ->
					%{
						"type" => type,
						"func_call_id" => msg_raw["1"],
						"func_call_source" => msg_raw["2"],
						"order_id" => msg_raw["3"],
						"user_id" => msg_raw["4"],
						"side" => msg_raw["5"],
						"amount" => msg_raw["6"],
						"rate" => msg_raw["7"],
						"offset" => msg_raw["8"],
						"datetime" => msg_raw["9"],
					}
				type == :NewTrade ->
					%{
						"type" => type,
						"trade_id" => msg_raw["1"],
						"buy_order_id" => msg_raw["2"],
						"sell_order_id" => msg_raw["3"],
						"buyer_user_id" => msg_raw["4"],
						"seller_user_id" => msg_raw["5"],
						"side" => msg_raw["6"],
						"amount" => msg_raw["7"],
						"rate" => msg_raw["8"],
						"buyer_fee" => msg_raw["9"],
						"seller_fee" => msg_raw["10"],
						"datetime" => msg_raw["11"],
					}
				Enum.member?([:NewForcedLiquidation, :NewExecTS, :NewExecTP, :NewExecSL], type) ->
					%{
						"type" => type,
						"order_id" => msg_raw["1"],
						"user_id" => msg_raw["2"],
						"side" => msg_raw["3"],
						"amount" => msg_raw["4"],
						"rate" => msg_raw["5"],
						"datetime" => msg_raw["6"],
					}
				type == :NewAccountFee ->
					%{
						"type" => type,
						"func_call_id" => msg_raw["1"],
						"user_id" => msg_raw["2"],
						"fee" => msg_raw["3"],
						"datetime" => msg_raw["4"],
					}
				type == :NewMarginInfo ->
					%{
						"type" => type,
						"user_id" => msg_raw["1"],
						"equity" => msg_raw["2"],
						"margin_level" => msg_raw["3"],
						"datetime" => msg_raw["4"],
					}
				type == :NewMarginCall ->
					%{
						"type" => type,
						"user_id" => msg_raw["1"],
						"datetime" => msg_raw["2"],
					}
				type == :NewFixRestart ->
					%{
						"type" => type,
						"status_code" => msg_raw["1"],
						"datetime" => msg_raw["2"],
					}
				type == :NewOrderStatus ->
					%{
						"type" => type,
						"order_id" => msg_raw["1"],
						"user_id" => msg_raw["2"],
						"status" => msg_raw["3"],
						"datetime" => msg_raw["4"],
					}
				type == :NewMarketStatus ->
					%{
						"type" => type,
						"status" => msg_raw["1"],
						"datetime" => msg_raw["2"],
					}
				type == :NewSnapshotOperation ->
					%{
						"type" => type,
						"op_code" => msg_raw["1"],
						"status_code" => msg_raw["2"],
						"datetime" => msg_raw["3"],
					}
			end
		end
	end
end