defmodule CalDAVClient.Event do
  @moduledoc """
  Allows for managing events on the calendar server.
  """

  import CalDAVClient.Tesla
  alias CalDAVClient.URL

  @type t :: %__MODULE__{
          icalendar: String.t(),
          url: String.t(),
          etag: String.t()
        }

  @enforce_keys [:icalendar, :url, :etag]
  defstruct @enforce_keys

  @doc """
  Creates an event (see [RFC 4791, section 5.3.2](https://tools.ietf.org/html/rfc4791#section-5.3.2)).
  """
  @callback create(
              CalDAVClient.Client.t(),
              calendar_url :: String.t(),
              event_id :: String.t(),
              event_icalendar :: String.t()
            ) ::
              {:ok, etag :: String.t() | nil} | {:error, any()}
  @spec create(
          CalDAVClient.Client.t(),
          calendar_url :: String.t(),
          event_id :: String.t(),
          event_icalendar :: String.t()
        ) ::
          {:ok, etag :: String.t() | nil} | {:error, any()}
  def create(client, calendar_url, event_id, event_icalendar) do
    # fail when event already exists
    headers = [{"If-None-Match", "*"}]

    with {:ok, event_url} <- URL.build_event_url(calendar_url, event_id) do
      case client
           |> make_tesla_client([
             CalDAVClient.Tesla.ContentTypeICalendarMiddleware,
             CalDAVClient.Tesla.ContentLengthMiddleware
           ])
           |> Tesla.put(event_url, event_icalendar, headers: headers) do
        {:ok, %Tesla.Env{status: code} = env} when code in [201, 204] ->
          etag = env |> Tesla.get_header("etag")
          {:ok, etag}

        error ->
          error
      end
    end
  end

  @doc """
  Updates a specific event (see [RFC 4791, section 5.3.2](https://tools.ietf.org/html/rfc4791#section-5.3.2)).

  ## Options
  * `etag` - a specific ETag used to ensure that the client overwrites the latest version of the event.
  """
  @callback update(
              CalDAVClient.Client.t(),
              calendar_url :: String.t(),
              event_id :: String.t(),
              event_icalendar :: String.t(),
              opts :: keyword()
            ) :: {:ok, etag :: String.t() | nil} | {:error, any()}
  @spec update(
          CalDAVClient.Client.t(),
          calendar_url :: String.t(),
          event_id :: String.t(),
          event_icalendar :: String.t(),
          opts :: keyword()
        ) :: {:ok, etag :: String.t() | nil} | {:error, any()}
  def update(client, calendar_url, event_id, event_icalendar, opts \\ []) do
    with {:ok, event_url} <- URL.build_event_url(calendar_url, event_id) do
      case client
           |> make_tesla_client([
             CalDAVClient.Tesla.ContentTypeICalendarMiddleware,
             CalDAVClient.Tesla.ContentLengthMiddleware,
             {CalDAVClient.Tesla.IfMatchMiddleware, etag: opts[:etag]}
           ])
           |> Tesla.put(event_url, event_icalendar) do
        {:ok, %Tesla.Env{status: code} = env} when code in [201, 204] ->
          etag = env |> Tesla.get_header("etag")
          {:ok, etag}

        error ->
          error
      end
    end
  end

  @doc """
  Deletes a specific event.

  ## Options
  * `etag` - a specific ETag used to ensure that the client overwrites the latest version of the event.
  """
  @callback delete(
              CalDAVClient.Client.t(),
              calendar_url :: String.t(),
              event_id :: String.t(),
              opts :: keyword()
            ) :: :ok | {:error, any()}
  @spec delete(
          CalDAVClient.Client.t(),
          calendar_url :: String.t(),
          event_id :: String.t(),
          opts :: keyword()
        ) :: :ok | {:error, any()}
  def delete(client, calendar_url, event_id, opts \\ []) do
    with {:ok, event_url} <- URL.build_event_url(calendar_url, event_id) do
      case client
           |> make_tesla_client([
             CalDAVClient.Tesla.ContentTypeICalendarMiddleware,
             CalDAVClient.Tesla.ContentLengthMiddleware,
             {CalDAVClient.Tesla.IfMatchMiddleware, etag: opts[:etag]}
           ])
           |> Tesla.delete(event_url) do
        {:ok, %Tesla.Env{status: 204}} ->
          :ok

        error ->
          error
      end
    end
  end

  @doc """
  Returns a specific event in the iCalendar format along with its ETag.
  """
  @callback get(CalDAVClient.Client.t(), String.t(), String.t()) ::
              {:ok, icalendar :: String.t(), etag :: String.t()} | {:error, any()}
  @spec get(CalDAVClient.Client.t(), String.t(), String.t()) ::
          {:ok, icalendar :: String.t(), etag :: String.t()} | {:error, any()}
  def get(client, calendar_url, event_id) do
    with {:ok, event_url} <- URL.build_event_url(calendar_url, event_id) do
      case client
           |> make_tesla_client()
           |> Tesla.get(event_url) do
        {:ok, %Tesla.Env{status: 200, body: icalendar} = env} ->
          etag = env |> Tesla.get_header("etag")
          {:ok, icalendar, etag}

        error ->
          error
      end
    end
  end

  @doc """
  Returns an event with the specified UID property
  (see [RFC 4791, section 7.8.6](https://tools.ietf.org/html/rfc4791#section-7.8.6)).
  """
  @callback find_by_uid(CalDAVClient.Client.t(), String.t(), String.t()) ::
              {:ok, t()} | {:error, any()}
  @spec find_by_uid(CalDAVClient.Client.t(), String.t(), String.t()) ::
          {:ok, t()} | {:error, any()}
  def find_by_uid(client, calendar_url, event_uid) do
    request_xml = CalDAVClient.XML.Builder.build_retrieval_of_event_by_uid_xml(event_uid)

    case client |> get_events_by_xml(calendar_url, request_xml) do
      {:ok, [event]} -> {:ok, event}
      {:ok, []} -> {:error, :not_found}
      error -> error
    end
  end

  @doc """
  Retrieves all events or its occurrences within a specific time range
  (see [RFC 4791, section 7.8.1](https://tools.ietf.org/html/rfc4791#section-7.8.1)).

  ## Options
  * `expand` - if `true`, recurring events will be expanded to occurrences, defaults to `false`.
  """
  @callback get_events(
              CalDAVClient.Client.t(),
              calendar_url :: String.t(),
              from :: DateTime.t(),
              to :: DateTime.t(),
              opts :: keyword()
            ) :: {:ok, [t()]} | {:error, any()}
  @spec get_events(
          CalDAVClient.Client.t(),
          calendar_url :: String.t(),
          from :: DateTime.t(),
          to :: DateTime.t(),
          opts :: keyword()
        ) :: {:ok, [t()]} | {:error, any()}
  def get_events(client, calendar_url, from, to, opts \\ []) do
    request_xml = CalDAVClient.XML.Builder.build_retrieval_of_events_xml(from, to, opts)
    client |> get_events_by_xml(calendar_url, request_xml)
  end

  @doc """
  Retrieves all events or its occurrences having an VALARM within a specific time range
  (see [RFC 4791, section 7.8.5](https://tools.ietf.org/html/rfc4791#section-7.8.5)).

  @doc \"""
  Retrieves all occurrences of events for given XML request body.
  """
  @callback get_events_by_xml(
              CalDAVClient.Client.t(),
              calendar_url :: String.t(),
              request_xml :: String.t()
            ) ::
              {:ok, [t()]} | {:error, any()}
  @spec get_events_by_xml(
          CalDAVClient.Client.t(),
          calendar_url :: String.t(),
          request_xml :: String.t()
        ) ::
          {:ok, [t()]} | {:error, any()}
  def get_events_by_xml(client, calendar_url, request_xml) do
    case client
         |> make_tesla_client([
           CalDAVClient.Tesla.ContentTypeXMLMiddleware,
           CalDAVClient.Tesla.ContentLengthMiddleware
         ])
         |> Tesla.request(
           method: :report,
           url: calendar_url,
           body: request_xml,
           headers: [{"Depth", "1"}],
           opts: [pre_auth_method: :get]
         ) do
      {:ok, %Tesla.Env{status: 207, body: response_xml}} ->
        events = response_xml |> CalDAVClient.XML.Parser.parse_events()
        {:ok, events}

      error ->
        error
    end
  end
end
