import Utils

defmodule Repo do
  use Ecto.Repo, otp_app: :daemon
end

defmodule Deal do
    require Lager
    use Ecto.Model

    schema "deal" do
        field :size,    :decimal
        field :price, :decimal
        field :orderBuyId, :integer
        field :orderSellId, :integer
        field :createdAt, :integer
        field :userBuyId, :integer
        field :userSellId, :integer
        field :buyerFee, :decimal
        field :sellerFee, :decimal
        field :side, :boolean
        field :currency, :string
    end

    def create(msg) do
        deal = %Deal{
            id: msg.trade_id,
            size: decimalify(msg.amount),
            price: decimalify(msg.rate),
            orderBuyId: msg.buy_order_id,
            orderSellId: msg.sell_order_id,
            createdAt: msg.datetime,
            userBuyId: msg.buyer_user_id,
            userSellId: msg.seller_user_id,
            buyerFee: decimalify(msg.buyer_fee),
            sellerFee: decimalify(msg.seller_fee),
            side: msg.side,
            currency: msg.currency,
        }
        
        try do
            Repo.insert(deal) 
            Lager.info "DB Deal:#{deal.id} inserted"
        rescue 
            _ -> 
                Repo.update(deal) 
                Lager.info "DB Deal:#{deal.id} updated"
        end
    end
end

defmodule Order do
    require Lager
    use Ecto.Model
    import Ecto.Query, only: [from: 2]

    schema "order" do
        field :userId, :integer
        field :size,    :decimal
        field :actualSize, :decimal
        field :price, :decimal
        field :createdAt, :integer
        field :updatedAt, :integer
        field :status, :string
        field :type, :string
        field :side, :boolean
        field :offset, :decimal
        field :currency, :string
    end
    @doc """
        Call when NewOrder recieved and order_event is 
        "PlaceLimit" or "PlaceMarket" or "AddSL" or "AddTP" or "AddTS" or "ForcedLiquidation"
    """
    def create(msg) do
        order = %Order{
            id: msg.order_id,
            userId: msg.user_id,
            size: decimalify(msg.original_amount),
            actualSize: decimalify(msg.actual_amount),
            price: decimalify(msg.rate),
            createdAt: msg.datetime,
            updatedAt: msg.datetime,
            status: "accepted",
            type: Messages.order_type(msg.order_event),
            side: msg.side,
            offset: decimalify(msg.offset),
            currency: msg.currency
        }
        try do
            Repo.insert(order) 
            Lager.info "DB Order:#{order.id} inserted"
        rescue
            _ -> 
                Repo.update(order) 
                Lager.info "DB Order:#{order.id} updated"
        end
    end

    @doc """
        Call when NewOrder recieved and order_event is "Cancel"
    """
    def cancel(msg) do
        check = Repo.all(from o in Order, where: o.id == ^msg.order_id)
        case check do
            [] -> nil
            [order] -> 
                order_new = %Order{order| 
                    actualSize: decimalify(msg.actual_amount),
                    status: "cancelled",
                    updatedAt: msg.datetime,
                }
                Lager.info "DB Order:#{order.id} cancelled"
                Repo.update(order_new) 
        end
        
    end

    @doc """
        Call when NewOrder recieved and order_event is
        "ExecSL" or "ExecTP" or "ExecTS"
    """
    def exec(msg) do
        check = Repo.all(from o in Order, where: o.id == ^msg.order_id)
        case check do
            [] -> nil
            [order] -> 
                order_new = %Order{order| 
                    actualSize: decimalify(msg.actual_amount),
                    status: "accepted",
                    updatedAt: msg.datetime,
                }
                Lager.info "DB Order:#{order.id} executed"
                Repo.update(order_new) 
        end
    end

    @doc """
        Call when NewOrderMatch recieved
    """
    def update(msg) do
        check = Repo.all(from o in Order, where: o.id == ^msg.order_id)
        case check do
            [] -> nil
            [order] -> 
                order_new = %Order{order| 
                    actualSize: decimalify(msg.actual_amount),
                    status: msg.status,
                    updatedAt: msg.datetime,
                }
                Lager.info "DB Order:#{order.id} updated"
                Repo.update(order_new) 
        end
        
    end
end