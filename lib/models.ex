defmodule Repo do
  use Ecto.Repo, adapter: Ecto.Adapters.Postgres

  def conf do
    parse_url "ecto://luciding:easypass@localhost/luciding"
  end
end

defmodule User do
    use Ecto.Model

    schema "lu_user" do
        field :username,    :string
        field :email, :string
        field :password, :string
        field :status,    :string
        field :today_dream_id, :integer
    end
end