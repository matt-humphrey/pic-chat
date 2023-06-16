defmodule PicChatWeb.PageController do
  use PicChatWeb, :controller

  def home(conn, _params) do
    html(conn, "<h1>Hello</h1>")
  end
end
