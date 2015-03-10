import Utils

defmodule Repo do
  use Ecto.Repo, adapter: Ecto.Adapters.Postgres
  import Ecto.Query, only: [from: 2]

  def conf do
    parse_url "ecto://postgres:password@localhost/exchange"
  end
end

defmodule Deal do
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
        rescue 
            _ -> Repo.update(deal) 
        end
    end
end

defmodule Order do
    use Ecto.Model
    import Ecto.Query, only: [from: 2]

    schema "order" do
        field :userId, :integer
        field :size,    :decimal
        field :price, :decimal
        field :createdAt, :integer
        field :updatedAt, :integer
        field :status, :string
        field :type, :string
        field :side, :boolean
        field :offset, :decimal
        field :currency, :string
    end

end