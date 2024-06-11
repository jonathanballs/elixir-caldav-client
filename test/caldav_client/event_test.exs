defmodule CalDAVClient.EventTest do
  use CalDAVClient.IntegrationTest

  alias CalDAVClient.URL

  @calendar_id "event_test"

  @event_id "event.ics"
  @event_uid "uid1@example.com"

  @event_icalendar """
  BEGIN:VCALENDAR
  PRODID:-//Elixir//CalDAV//EN
  VERSION:2.0
  BEGIN:VEVENT
  UID:#{@event_uid}
  DTSTAMP:20210101T120000Z
  DTSTART:20210101T120000Z
  END:VEVENT
  END:VCALENDAR
  """

  @event_icalendar_missing_dtstart """
  BEGIN:VCALENDAR
  PRODID:-//Elixir//CalDAV//EN
  VERSION:2.0
  BEGIN:VEVENT
  UID:#{@event_uid}
  DTSTAMP:20210101T120000Z
  END:VEVENT
  END:VCALENDAR
  """

  @event_icalendar_malformed_icalendar "bad"

  @from DateTime.from_naive!(~N[0000-01-01 00:00:00], "Etc/UTC")
  @to DateTime.from_naive!(~N[9999-12-31 23:59:59], "Etc/UTC")

  setup %{client: client} do
    {:ok, calendar_url} = URL.build_calendar_url(client, @calendar_id)
    on_exit(fn -> client |> CalDAVClient.Calendar.delete(calendar_url) end)
    %{calendar_url: calendar_url}
  end

  describe "when calendar does not exist" do
    test "returns error on event create", %{client: client, calendar_url: calendar_url} do
      assert {:error, :not_found} =
               client |> CalDAVClient.Event.create(calendar_url, @event_id, @event_icalendar)
    end

    test "returns error on event update", %{client: client, calendar_url: calendar_url} do
      assert {:error, :not_found} =
               client |> CalDAVClient.Event.update(calendar_url, @event_id, @event_icalendar)
    end

    test "returns error on event delete", %{client: client, calendar_url: calendar_url} do
      assert {:error, :not_found} = client |> CalDAVClient.Event.delete(calendar_url, @event_id)
    end

    test "returns error on event get", %{client: client, calendar_url: calendar_url} do
      assert {:error, :not_found} = client |> CalDAVClient.Event.get(calendar_url, @event_id)
    end

    test "returns error on event find by UID", %{client: client, calendar_url: calendar_url} do
      assert {:error, :not_found} =
               client |> CalDAVClient.Event.find_by_uid(calendar_url, @event_uid)
    end

    test "returns error on get events", %{client: client, calendar_url: calendar_url} do
      assert {:error, :not_found} =
               client |> CalDAVClient.Event.get_events(calendar_url, @from, @to)
    end
  end

  describe "when calendar exists but event does not exist" do
    setup %{client: client, calendar_url: calendar_url} do
      :ok =
        client
        |> CalDAVClient.Calendar.create(calendar_url, name: "Name", description: "Description")

      :ok
    end

    test "returns ok on event create", %{client: client, calendar_url: calendar_url} do
      assert {:ok, _etag} =
               client |> CalDAVClient.Event.create(calendar_url, @event_id, @event_icalendar)
    end

    test "returns error on event create when DTSTART is missing", %{
      client: client,
      calendar_url: calendar_url
    } do
      assert {:error, _reason} =
               client
               |> CalDAVClient.Event.create(
                 calendar_url,
                 @event_id,
                 @event_icalendar_missing_dtstart
               )
    end

    test "returns unsupported media type error when icalendar malformed", %{
      client: client,
      calendar_url: calendar_url
    } do
      assert {:error, :unsupported_media_type} =
               client
               |> CalDAVClient.Event.create(
                 calendar_url,
                 @event_id,
                 @event_icalendar_malformed_icalendar
               )
    end

    test "returns error not found on event delete", %{client: client, calendar_url: calendar_url} do
      assert {:error, :not_found} = client |> CalDAVClient.Event.delete(calendar_url, @event_id)
    end

    test "returns error on event get", %{client: client, calendar_url: calendar_url} do
      assert {:error, :not_found} = client |> CalDAVClient.Event.get(calendar_url, @event_id)
    end

    test "returns error on event find by UID", %{client: client, calendar_url: calendar_url} do
      assert {:error, :not_found} =
               client |> CalDAVClient.Event.find_by_uid(calendar_url, @event_uid)
    end

    test "returns empty list on get events", %{client: client, calendar_url: calendar_url} do
      assert {:ok, []} = client |> CalDAVClient.Event.get_events(calendar_url, @from, @to)
    end
  end

  describe "when both calendar and event exist" do
    setup %{client: client, calendar_url: calendar_url} do
      :ok =
        client
        |> CalDAVClient.Calendar.create(calendar_url, name: "Name", description: "Description")

      {:ok, _etag} =
        client |> CalDAVClient.Event.create(calendar_url, @event_id, @event_icalendar)

      :ok
    end

    test "returns error already exists on event create", %{
      client: client,
      calendar_url: calendar_url
    } do
      assert {:error, :already_exists} =
               client |> CalDAVClient.Event.create(calendar_url, @event_id, @event_icalendar)
    end

    test "returns ok on event update", %{client: client, calendar_url: calendar_url} do
      assert {:ok, _etag} =
               client |> CalDAVClient.Event.update(calendar_url, @event_id, @event_icalendar)
    end

    test "returns ok on event delete", %{client: client, calendar_url: calendar_url} do
      assert :ok = client |> CalDAVClient.Event.delete(calendar_url, @event_id)
    end

    test "returns ok on event get", %{client: client, calendar_url: calendar_url} do
      assert {:ok, @event_icalendar, _etag} =
               client |> CalDAVClient.Event.get(calendar_url, @event_id)
    end

    test "returns ok on event find by UID", %{client: client, calendar_url: calendar_url} do
      assert {:ok, %CalDAVClient.Event{icalendar: @event_icalendar}} =
               client |> CalDAVClient.Event.find_by_uid(calendar_url, @event_uid)
    end

    test "returns list with single event on get events", %{
      client: client,
      calendar_url: calendar_url
    } do
      assert {:ok, [%CalDAVClient.Event{icalendar: @event_icalendar}]} =
               client |> CalDAVClient.Event.get_events(calendar_url, @from, @to, expand: false)
    end
  end
end
