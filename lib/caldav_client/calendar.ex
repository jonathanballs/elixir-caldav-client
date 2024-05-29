defmodule CalDAVClient.Calendar do
  @moduledoc """
  Allows for managing calendars on the calendar server.
  """

  import CalDAVClient.HTTP.Error
  import CalDAVClient.Tesla

  @type t :: %__MODULE__{
          url: String.t(),
          name: String.t(),
          type: String.t(),
          timezone: String.t()
        }
  @enforce_keys [:url, :name, :type, :timezone]
  defstruct @enforce_keys

  @xml_middlewares [
    CalDAVClient.Tesla.ContentTypeXMLMiddleware,
    CalDAVClient.Tesla.ContentLengthMiddleware
  ]

  @doc """
  Fetches the list of calendars (see [RFC 4791, section 4.2](https://tools.ietf.org/html/rfc4791#section-4.2)).
  """
  @spec list(CalDAVClient.Client.t()) ::
          {:ok, [t()]} | {:error, any()}
  def list(caldav_client) do
    with {:ok, user_principal_url} <- get_user_principal(caldav_client),
         {:ok, calendar_home_set} <- get_calendar_home_set(caldav_client, user_principal_url) do
      url =
        caldav_client.server_url
        |> URI.parse()
        |> Map.put(:path, calendar_home_set)
        |> URI.to_string()

      case caldav_client
           |> make_tesla_client(@xml_middlewares)
           |> Tesla.request(
             method: :propfind,
             url: url,
             headers: [
               {"Depth", "1"},
               {"Prefer", "return-minimal"}
             ],
             body: CalDAVClient.XML.Builder.build_list_calendar_xml()
           ) do
        {:ok, %Tesla.Env{status: 207, body: response_xml}} ->
          calendars = response_xml |> CalDAVClient.XML.Parser.parse_calendars()
          {:ok, calendars}

        {:ok, %Tesla.Env{status: code}} ->
          {:error, reason_atom(code)}

        {:error, _reason} = error ->
          error
      end
    end
  end

  defp get_user_principal(caldav_client) do
    case caldav_client
         |> make_tesla_client(@xml_middlewares)
         |> Tesla.request(
           method: :propfind,
           url: "",
           headers: [],
           body: CalDAVClient.XML.Builder.build_get_user_principal_xml()
         ) do
      {:ok, %Tesla.Env{status: 207, body: response_xml}} ->
        calendars = response_xml |> CalDAVClient.XML.Parser.parse_user_principal()
        {:ok, calendars}

      {:ok, %Tesla.Env{status: code}} ->
        {:error, reason_atom(code)}

      {:error, _reason} = error ->
        error
    end
  end

  defp get_calendar_home_set(%CalDAVClient.Client{} = caldav_client, user_principal_url) do
    base_path = URI.parse(caldav_client.server_url).path
    ^base_path <> user_principal_url = user_principal_url

    case caldav_client
         |> make_tesla_client(@xml_middlewares)
         |> Tesla.request(
           method: :propfind,
           url: user_principal_url,
           headers: [
             {"Depth", "0"},
             {"Prefer", "return-minimal"}
           ],
           body: CalDAVClient.XML.Builder.build_calendar_home_set_xml()
         ) do
      {:ok, %Tesla.Env{status: 207, body: response_xml}} ->
        calendars = response_xml |> CalDAVClient.XML.Parser.parse_calendar_home_set()
        {:ok, calendars}

      {:ok, %Tesla.Env{status: code}} ->
        {:error, reason_atom(code)}

      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Creates a calendar (see [RFC 4791, section 5.3.1.2](https://tools.ietf.org/html/rfc4791#section-5.3.1.2)).

  ## Options
  * `name` - calendar name.
  * `description` - calendar description.
  """
  @spec create(CalDAVClient.Client.t(), calendar_url :: String.t(), opts :: keyword()) ::
          :ok | {:error, any()}
  def create(caldav_client, calendar_url, opts \\ []) do
    case caldav_client
         |> make_tesla_client(@xml_middlewares)
         |> Tesla.request(
           method: :mkcalendar,
           url: calendar_url,
           body: CalDAVClient.XML.Builder.build_create_calendar_xml(opts)
         ) do
      {:ok, %Tesla.Env{status: code}} ->
        case code do
          201 -> :ok
          405 -> {:error, :already_exists}
          _ -> {:error, reason_atom(code)}
        end

      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Updates a specific calendar.

  ## Options
  * `name` - calendar name.
  * `description` - calendar description.
  """
  @spec update(CalDAVClient.Client.t(), calendar_url :: String.t(), opts :: keyword()) ::
          :ok | {:error, any()}
  def update(caldav_client, calendar_url, opts \\ []) do
    case caldav_client
         |> make_tesla_client(@xml_middlewares)
         |> Tesla.request(
           method: :proppatch,
           url: calendar_url,
           body: CalDAVClient.XML.Builder.build_update_calendar_xml(opts)
         ) do
      {:ok, %Tesla.Env{status: code}} ->
        case code do
          207 -> :ok
          _ -> {:error, reason_atom(code)}
        end

      {:error, _reason} = error ->
        error
    end
  end

  @doc """
  Deletes a specific calendar.
  """
  @spec delete(CalDAVClient.Client.t(), calendar_url :: String.t()) :: :ok | {:error, any()}
  def delete(caldav_client, calendar_url) do
    case caldav_client
         |> make_tesla_client()
         |> Tesla.delete(calendar_url) do
      {:ok, %Tesla.Env{status: code}} ->
        case code do
          204 -> :ok
          _ -> {:error, reason_atom(code)}
        end

      {:error, _reason} = error ->
        error
    end
  end
end
