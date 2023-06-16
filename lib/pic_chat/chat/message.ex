defmodule PicChat.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :content, :string
    field :from, :string
    field :picture, :string
    belongs_to :user, PicChat.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :from, :picture, :user_id])
    |> validate_required([:content, :from])
  end
end
