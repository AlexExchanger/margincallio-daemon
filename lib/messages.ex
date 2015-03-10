use Jazz
import Utils

defmodule Messages do
	def parse(nil) do
		nil
	end
	def parse(msg) when is_map(msg) do
		type = case msg["0"] do
			0 -> :NewBalance
			1 -> :NewMarginInfo
			2 -> :NewMarginCall
			3 -> :NewTicker
			4 -> :NewOrderBookTop
			5 -> :NewOrder
			6 -> :NewOrderMatch
			7 -> :NewTrade
			8 -> :NewAccountFee
			_ -> nil #log error
		end
		parsed_msg = case type do
			:NewBalance -> Messages.parse_new_balance(msg)
			:NewMarginInfo -> Messages.parse_new_margin_info(msg)
			:NewMarginCall -> Messages.parse_new_margin_call(msg)
			:NewTicker -> Messages.parse_new_ticker(msg)
			:NewOrderBookTop -> Messages.parse_new_order_book_top(msg)
			:NewOrder -> Messages.parse_new_order(msg)
			:NewOrderMatch -> Messages.parse_new_order_match(msg)
			:NewTrade -> Messages.parse_new_trade(msg)
			:NewAccountFee -> Messages.parse_new_account_fee(msg)
			nil -> nil
		end
		if parsed_msg != nil do
			Map.put(parsed_msg, :type, type)
		end
	end
	def parse(_) do
		nil
	end

	def parse_new_balance(msg) do
		%{
			user_id: msg["1"],
			currency: String.upcase(msg["2"]),
			available_funds: msg["3"],
			blocked_funds: msg["4"],
			datetime: msg["5"],
		}
	end

	def parse_new_margin_info(msg) do
		%{
			user_id: msg["1"],
			equity: msg["2"],
			margin: msg["3"],
			free_margin: msg["4"],
			margin_level: msg["5"],
			datetime: msg["6"],
		}
	end

	def parse_new_margin_call(msg) do
		%{
			user_id: msg["1"],
			datetime: msg["2"],
		}
	end

	def parse_new_ticker(msg) do
		%{
			currency: String.upcase(msg["1"]),
			bid_price: msg["2"],
			ask_price: msg["3"],
			datetime: msg["4"],
		}
	end

	def parse_new_order_book_top(msg) do
		%{
			currency: String.upcase(msg["1"]),
			side: msg["2"] == 1,
			levels: msg["3"],
			datetime: msg["4"],
		}
	end

	def parse_new_order(msg) do
		%{
			order_event: parse_order_event(msg["1"]),
			currency: String.upcase(msg["4"]),
			order_id: msg["5"],
			user_id: msg["6"],
			side: msg["7"] == 1,
			amount: msg["8"],
			rate: msg["9"],
			offset: msg["10"],
			datetime: msg["11"],
		}
	end

	def parse_new_order_match(msg) do
		%{
			currency: String.upcase(msg["1"]),
			order_id: msg["2"],
			user_id: msg["3"],
			actual_amount: msg["4"],
			status: if msg["5"] == 0 do "PartiallyFilled" else "Filled" end,
			datetime: msg["6"],
		}
	end

	def parse_new_trade(msg) do
		%{
			currency: String.upcase(msg["1"]),
			trade_id: msg["2"],
			buy_order_id: msg["3"],
			sell_order_id: msg["4"],
			buyer_user_id: msg["5"],
			seller_user_id: msg["6"],
			side: msg["7"] == 1,
			amount: msg["8"],
			rate: msg["9"],
			buyer_fee: msg["10"],
			seller_fee: msg["11"],
			datetime: msg["12"],
		}
	end

	def parse_new_account_fee(msg) do
		%{
			user_id: msg["2"],
			currency: String.upcase(msg["3"]),
			fee: msg["4"],
			datetime: msg["5"],
		}
	end

	def parse_order_event(event_code) do
		case event_code do
			0 -> "PlaceLimit"
			1 -> "PlaceMarket"
			2 -> "ExecSL"
			3 -> "ExecTP"
			4 -> "ExecTS"
			5 -> "AddSL"
			6 -> "AddTP"
			7 -> "AddTS"
			8 -> "Cancel"
			9 -> "ForcedLiquidation"
		end
	end



	def publify (%{type: :NewBalance} = msg) do
		JSON.encode!%{
			type: to_string(msg.type),
			currency: msg.currency,
			available_funds: stringify(msg.available_funds, 8),
			blocked_funds: stringify(msg.blocked_funds, 8),
			timestamp: timestampify(msg.datetime),
		}
	end
	def publify (%{type: :NewMarginInfo} = msg) do
		JSON.encode!%{
			type: to_string(msg.type),	
			equity: stringify(msg.equity, 4),
			margin: stringify(msg.margin, 4),
			free_margin: stringify(msg.free_margin, 4),
			margin_level: stringify(msg.margin_level,2),
			timestamp: timestampify(msg.datetime),
		}
	end
	def publify (%{type: :NewMarginCall} = msg) do
		JSON.encode!%{
			type: to_string(msg.type),
			timestamp: timestampify(msg.datetime),
		}
	end
	def publify (%{type: :NewTicker} = msg) do
		JSON.encode!%{
			type: to_string(msg.type),
			currency: msg.currency,
			bid_price: stringify(msg.bid_price,4),
			ask_price: stringify(msg.ask_price,4),
			timestamp: timestampify(msg.datetime),
		}
	end
	def publify (%{type: :NewOrderBookTop} = msg) do
		JSON.encode!%{
			type: to_string(msg.type),
			currency: msg.currency,
			side: msg.side,
			levels: Enum.map(msg.levels, &publify_levels/1),
			timestamp: timestampify(msg.datetime),
		}
	end
	def publify (%{type: :NewOrder} = msg) do
		JSON.encode!%{
			type: to_string(msg.type),
			order_event: msg.order_event,
			currency: msg.currency,
			order_id: msg.order_id,
			side: msg.side,
			amount: stringify(msg.amount, 4),
			rate: stringify(msg.rate, 4),
			offset: stringify(msg.offset, 4),
			timestamp: timestampify(msg.datetime),
		}
	end
	def publify (%{type: :NewOrderMatch} = msg) do
		JSON.encode!%{
			type: to_string(msg.type),
			currency: msg.currency,
			order_id: msg.order_id,
			actual_amount: stringify(msg.actual_amount,4),
			status: msg.status,
			timestamp: timestampify(msg.datetime),
		}
	end
	def publify (%{type: :NewTrade} = msg) do
		JSON.encode!%{
			type: to_string(msg.type)<>"Public",
			currency: msg.currency,
			trade_id: msg.trade_id,
			side: msg.side,
			amount: stringify(msg.amount,4),
			rate: stringify(msg.rate, 4),
			timestamp: timestampify(msg.datetime),
		}
	end

	def publify (%{type: :NewAccountFee} = msg) do
		JSON.encode!%{
			type: to_string(msg.type),
			currency: msg.currency,
			fee: stringify(msg.fee,4),
			timestamp: timestampify(msg.datetime),
		}
	end

	def publify_buyer (%{type: :NewTrade} = msg) do
		JSON.encode!%{
			type: to_string(msg.type)<>"Buyer",
			currency: msg.currency,
			order_id: msg.buy_order_id,
			fee: stringify(msg.buyer_fee,4),
			trade_id: msg.trade_id,
			side: msg.side,
			amount: stringify(msg.amount,4),
			rate: stringify(msg.rate, 4),
			timestamp: timestampify(msg.datetime),
		}
	end
	def publify_seller (%{type: :NewTrade} = msg) do
		JSON.encode!%{
			type: to_string(msg.type)<>"Seller",
			currency: msg.currency,
			order_id: msg.sell_order_id,
			fee: stringify(msg.seller_fee,4),
			trade_id: msg.trade_id,
			side: msg.side,
			amount: stringify(msg.amount,4),
			rate: stringify(msg.rate, 4),
			timestamp: timestampify(msg.datetime),
		}
	end

	def publify_levels([amount, rate]) do
		%{
			amount: stringify(amount,4),
			rate: stringify(rate, 4),
			sum: stringify(amount*rate, 2),
		}
	end
	def handle (%{type: :NewBalance} = msg) do
		Bullet.pub({:user,msg.user_id,msg.currency}, publify(msg))
	end
	def handle (%{type: :NewMarginInfo} = msg) do
		Bullet.pub({:user, msg.user_id}, publify(msg))
	end
	def handle (%{type: :NewMarginCall} = msg) do
		Bullet.pub({:user, msg.user_id}, publify(msg))
	end
	def handle (%{type: :NewTicker} = msg) do
		Bullet.pub({:general, msg.currency}, publify(msg))
	end
	def handle (%{type: :NewOrderBookTop} = msg) do
		Bullet.pub({:general, msg.currency}, publify(msg))
	end
	def handle (%{type: :NewOrder} = msg) do
		Bullet.pub({:user, msg.user_id, msg.currency}, publify(msg))
	end
	def handle (%{type: :NewOrderMatch} = msg) do
		Bullet.pub({:user, msg.user_id, msg.currency}, publify(msg))
	end
	def handle (%{type: :NewTrade} = msg) do
		Deal.create(msg)
		Bullet.pub({:general, msg.currency}, publify(msg))
		Bullet.pub({:user, msg.buyer_user_id, msg.currency}, publify_buyer(msg))
		Bullet.pub({:user, msg.seller_user_id, msg.currency}, publify_seller(msg))
	end
	def handle (%{type: :NewAccountFee} = msg) do
		Bullet.pub({:user, msg.user_id, msg.currency}, publify(msg))
	end

	def handle(nil) do 
	end
end
