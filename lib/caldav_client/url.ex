defmodule CalDAVClient.URL do
  @moduledoc """
  Builds and fetches relevant URLs according to CalDAV specification.
  """

  alias CalDAVClient.Client
  import CalDAVClient.HTTP.Error
  import CalDAVClient.Tesla

  @xml_middlewares [
    CalDAVClient.Tesla.ContentTypeXMLMiddleware,
    CalDAVClient.Tesla.ContentLengthMiddleware
  ]

  @spec get_current_user_principal(Client.t()) ::
          {:ok, String.t()} | {:error, :not_found}
  def get_current_user_principal(%Client{} = client) do
    case client
         |> make_tesla_client(@xml_middlewares)
         |> Tesla.request(
           method: :propfind,
           url: "",
           headers: [],
           body: CalDAVClient.XML.Builder.build_get_user_principal_xml()
         ) do
      {:ok, %Tesla.Env{status: 207, body: response_xml}} ->
        CalDAVClient.XML.Parser.parse_user_principal(response_xml)

      {:ok, %Tesla.Env{status: code}} ->
        {:error, reason_atom(code)}

      {:error, _reason} = error ->
        error
    end
  end

  @spec get_calendar_home_set(Client.t()) :: {:ok, String.t()} | {:error, :not_found}
  def get_calendar_home_set(%Client{} = client) do
    with {:ok, user_principal_url} <- get_current_user_principal(client) do
      case client
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
          CalDAVClient.XML.Parser.parse_calendar_home_set(response_xml)

        {:ok, %Tesla.Env{status: code}} ->
          {:error, reason_atom(code)}

        {:error, _reason} = error ->
          error
      end
    end
  end

  @doc """
  Builds calendar URL for a given user with calendar ID.
  """
  @spec build_calendar_url(Client.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def build_calendar_url(client, calendar_token_id) do
    with {:ok, calendar_home_set} <- get_calendar_home_set(client),
         calendar_token_id <- URI.encode(calendar_token_id) do
      {:ok, Path.absname(calendar_token_id, calendar_home_set) <> "/"}
    end
  end

  @doc """
  Builds event URL for given user, calendar id and event_id
  """
  @spec build_event_url(Client.t(), String.t(), String.t()) :: String.t()
  def build_event_url(client, calendar_id, event_id) do
    with {:ok, calendar_url} <- build_calendar_url(client, calendar_id),
         event_id <- URI.encode(event_id) do
      Path.absname(event_id, calendar_url)
    end
  end
end
