defmodule CalDAVClient.Calendar do
  @moduledoc """
  Allows for managing calendars on the calendar server.
  """

  import CalDAVClient.Tesla
  alias CalDAVClient.URL

  @type t :: %__MODULE__{
          url: String.t(),
          name: String.t(),
          type: String.t(),
          timezone: String.t(),
          color: String.t(),
          description: String.t()
        }
  @enforce_keys [:url, :name, :type, :timezone, :color, :description]
  defstruct @enforce_keys

  @xml_middlewares [
    CalDAVClient.Tesla.ContentTypeXMLMiddleware,
    CalDAVClient.Tesla.ContentLengthMiddleware
  ]

  @doc """
  Fetches the list of calendars (see [RFC 4791, section 4.2](https://tools.ietf.org/html/rfc4791#section-4.2)).
  """
  @callback list(CalDAVClient.Client.t()) ::
              {:ok, [t()]} | {:error, any()}
  @spec list(CalDAVClient.Client.t()) ::
          {:ok, [t()]} | {:error, any()}
  def list(client) do
    with {:ok, calendar_home_set} <- URL.get_calendar_home_set(client) do
      case client
           |> make_tesla_client(@xml_middlewares)
           |> Tesla.request(
             method: :propfind,
             url: calendar_home_set,
             headers: [
               {"Depth", "1"},
               {"Prefer", "return-minimal"}
             ],
             body: CalDAVClient.XML.Builder.build_list_calendar_xml()
           ) do
        {:ok, %Tesla.Env{status: 207, body: response_xml}} ->
          calendars = response_xml |> CalDAVClient.XML.Parser.parse_calendars()
          {:ok, calendars}

        {:ok, %Tesla.Env{} = env} ->
          {:error, env}

        error ->
          error
      end
    end
  end

  @doc """
  Creates a calendar (see [RFC 4791, section 5.3.1.2](https://tools.ietf.org/html/rfc4791#section-5.3.1.2)).

  ## Options
  * `name` - calendar name.
  * `description` - calendar description.
  """
  @callback create(CalDAVClient.Client.t(), String.t(), opts :: keyword()) ::
              :ok | {:error, any()}
  @spec create(CalDAVClient.Client.t(), String.t(), opts :: keyword()) ::
          :ok | {:error, any()}
  def create(client, calendar_url, opts \\ []) do
    case client
         |> make_tesla_client(@xml_middlewares)
         |> Tesla.request(
           method: :mkcalendar,
           url: calendar_url,
           body: CalDAVClient.XML.Builder.build_create_calendar_xml(opts)
         ) do
      {:ok, %Tesla.Env{status: 201}} ->
        :ok

      {:ok, %Tesla.Env{} = env} ->
        {:error, env}

      error ->
        error
    end
  end

  @doc """
  Updates a specific calendar.

  ## Options
  * `name` - calendar name.
  * `description` - calendar description.
  """
  @callback update(CalDAVClient.Client.t(), String.t(), opts :: keyword()) ::
              :ok | {:error, any()}
  @spec update(CalDAVClient.Client.t(), String.t(), opts :: keyword()) ::
          :ok | {:error, any()}
  def update(client, calendar_url, opts \\ []) do
    case client
         |> make_tesla_client(@xml_middlewares)
         |> Tesla.request(
           method: :proppatch,
           url: calendar_url,
           body: CalDAVClient.XML.Builder.build_update_calendar_xml(opts)
         ) do
      {:ok, %Tesla.Env{status: 207}} ->
        :ok

      {:ok, %Tesla.Env{} = env} ->
        {:error, env}

      error ->
        error
    end
  end

  @doc """
  Deletes a specific calendar.
  """
  @callback delete(CalDAVClient.Client.t(), String.t()) :: :ok | {:error, any()}
  @spec delete(CalDAVClient.Client.t(), String.t()) :: :ok | {:error, any()}
  def delete(client, calendar_url) do
    case client
         |> make_tesla_client()
         |> Tesla.delete(calendar_url) do
      {:ok, %Tesla.Env{status: 204}} ->
        :ok

      {:ok, %Tesla.Env{} = env} ->
        {:error, env}

      error ->
        error
    end
  end
end
