defmodule CalDAVClient.AuthenticationTest do
  use CalDAVClient.IntegrationTest

  @calendar_id "calendar_id"
  @event_id "event_id"

  @event_icalendar """
  BEGIN:VCALENDAR
  PRODID:-//Elixir//CalDAV//EN
  VERSION:2.0
  BEGIN:VEVENT
  UID:uid1@example.com
  DTSTAMP:20210101T120000Z
  DTSTART:20210101T120000Z
  END:VEVENT
  END:VCALENDAR
  """

  setup %{client: client} do
    {:ok, calendar_url} = CalDAVClient.URL.build_calendar_url(client, @calendar_id)
    :ok = client |> CalDAVClient.Calendar.create(calendar_url)
    {:ok, _etag} = client |> CalDAVClient.Event.create(calendar_url, @event_id, @event_icalendar)

    on_exit(fn -> client |> CalDAVClient.Calendar.delete(calendar_url) end)
    %{calendar_url: calendar_url}
  end

  test "passes on valid credentials", %{client: client, calendar_url: calendar_url} do
    assert {:ok, _icalendar, _etag} = client |> CalDAVClient.Event.get(calendar_url, @event_id)
  end

  test "fails on invalid credentials", %{
    invalid_client: invalid_client,
    calendar_url: calendar_url
  } do
    assert {:error, :unauthorized} =
             invalid_client |> CalDAVClient.Event.get(calendar_url, @event_id)
  end
end
