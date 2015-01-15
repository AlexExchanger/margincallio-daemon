defmodule Repo do
  use Ecto.Repo, adapter: Ecto.Adapters.Postgres
  import Ecto.Query, only: [from: 2]

  def conf do
    parse_url "ecto://postgres:password@localhost/exchange"
  end
end

defmodule Deal do
    use Ecto.Model

    schema "deal_BTCUSD" do
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
    end
end

defmodule Order do
    use Ecto.Model
    import Ecto.Query, only: [from: 2]

    schema "order_BTCUSD" do
        field :userId, :integer
        field :size,    :decimal
        field :offset, :decimal
        field :price, :decimal
        field :createdAt, :integer
        field :updatedAt, :integer
        field :status, :string
        field :type, :string
        field :side, :boolean
    end

    def get_by_id(order_id) do
        case Repo.all(from o in Order, where: o.id == ^order_id) do
            [order] -> order
            [] -> %Order{id: order_id}
        end
    end
end