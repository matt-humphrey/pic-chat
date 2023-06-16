defmodule PicChatWeb.MessageLive.FormComponent do
  use PicChatWeb, :live_component

  alias PicChat.Chat

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage message records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="message-form"
        multipart
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="flex flex-col space-y-4">
          <.input field={@form[:content]} type="text" label="Content"/>
          <.input field={@form[:from]} type="text" label="From" />
          <.input field={@form[:user_id]} type="hidden" value={@current_user.id} />
          <label id="drag-n-drop" class="bg-gray-200 w-full mb-2 p-10 text-center hover:cursor-pointer" phx-drop-target={ @uploads.picture.ref }>
            Click or drag and drop to upload image
            <.live_file_input upload={@uploads.picture} style="display: none;" />
          </label>
        </div>
        <:actions>
          <.button phx-disable-with="Saving...">Save Message</.button>
        </:actions>
      </.simple_form>
      <%= for picture <- @uploads.picture.entries do %>
        <div class="mt-4">
        <.live_img_preview entry={picture} width="60" />
        </div>
        <progress value={picture.progress} max="100" />
        <%= for err <- upload_errors(@uploads.picture, picture) do %>
          <.error><%= err %></.error>
        <% end %>
      <% end %>
    </div>
    """
  end

  @impl true
  def update(%{message: message} = assigns, socket) do
    changeset = Chat.change_message(message)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)
     |> allow_upload(:picture,
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1,
       max_file_size: 9_000_000,
       auto_upload: true
       )}
  end

  @impl true
  def handle_event("validate", %{"message" => message_params}, socket) do
    changeset =
      socket.assigns.message
      |> Chat.change_message(message_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"message" => message_params}, socket) do
    save_message(socket, socket.assigns.action, message_params)
  end

  defp save_message(socket, :edit, params) do
    message_params = params_with_picture(socket, params)

    case Chat.update_message(socket.assigns.message, message_params) do
      {:ok, message} ->
        notify_parent({:edit, message})
        PicChatWeb.Endpoint.broadcast("messages", "edit", message)

        {:noreply,
         socket
         |> put_flash(:info, "Message updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_message(socket, :new, params) do
    message_params = params_with_picture(socket, params)

    case Chat.create_message(message_params) do
      {:ok, message} ->
        notify_parent({:new, message})
        PicChatWeb.Endpoint.broadcast_from(self(), "messages", "new", message)

        {:noreply,
         socket
         |> put_flash(:info, "Message created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp params_with_picture(socket, params) do
    path =
      socket
      |> consume_uploaded_entries(:picture, &upload_static_file/2)
      |> List.first
    Map.put(params, "picture", path)
  end

  defp upload_static_file(%{path: path}, _entry) do
    # Plug in your production image file persistence implementation here!
    filename = Path.basename(path)
    dest = Path.join("priv/static/images", filename)
    File.cp!(path, dest)
    {:ok, ~p"/images/#{filename}"}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
