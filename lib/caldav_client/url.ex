defmodule CalDAVClient.URL do
  @moduledoc """
  Builds and fetches relevant URLs according to CalDAV specification.
  """

  alias CalDAVClient.Client
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
           url: client.server_url,
           headers: [],
           body: CalDAVClient.XML.Builder.build_get_user_principal_xml()
         ) do
      {:ok, %Tesla.Env{status: 207, body: response_xml}} ->
        CalDAVClient.XML.Parser.parse_user_principal(response_xml)

      {:ok, %Tesla.Env{} = env} ->
        {:error, env}

      error ->
        error
    end
  end

  @spec get_calendar_home_set(Client.t()) :: {:ok, String.t()} | {:error, :not_found}
  def get_calendar_home_set(%Client{} = client) do
    with {:ok, user_principal_url} <-
           get_current_user_principal(client) do
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

        error ->
          error
      end
    end
  end

  @doc """
  Builds calendar URL for a given user with calendar ID.
  """
  @callback build_calendar_url(Client.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  @spec build_calendar_url(Client.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def build_calendar_url(client, calendar_token_id) do
    with {:ok, calendar_home_set} <- get_calendar_home_set(client),
         calendar_token_id <- URI.encode(calendar_token_id) do
      {:ok, merge(calendar_home_set, calendar_token_id) <> "/"}
    end
  end

  @doc """
  Builds event URL for given user, calendar id and event_id
  """
  @callback build_event_url(String.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  @spec build_event_url(String.t(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def build_event_url(calendar_url, event_id) do
    event_id = URI.encode(event_id)
    {:ok, Path.absname(event_id, calendar_url)}
  end

  def merge(base, relative) do
    base_uri =
      URI.parse(base)

    %{base_uri | path: join(base_uri.path, relative)}
    |> to_string()
  end

  defp join(base, url) do
    case {String.last(to_string(base)), url} do
      {nil, url} ->
        join("/", url)

      {_, "/" <> rest} ->
        "/" <> rest

      {"/", rest} ->
        base <> rest

      {_, _} ->
        base <> "/" <> url
        #
        # {_, rest} -> base <> "/" <> rest
    end
  end
end
