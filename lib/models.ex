defmodule Repo do
  use Ecto.Repo, adapter: Ecto.Adapters.Postgres

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
    end
end

defmodule Order do
    use Ecto.Model

    schema "order_BTCUSD" do
        field :userId, :integer
        field :size,    :decimal
        field :rate, :decimal
        field :price, :decimal
        field :createdAt, :integer
        field :updatedAt, :integer
        field :status, :string
        field :type, :string
        field :side, :boolean
    end
end