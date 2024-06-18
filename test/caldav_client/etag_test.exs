defmodule CalDAVClient.ETagTest do
  use ExUnit.Case

  use CalDAVClient.IntegrationTest
  alias CalDAVClient.URL

  @calendar_id "etag_test"

  @event_id "event.ics"

  @event_icalendar """
  BEGIN:VCALENDAR
  PRODID:-//xyz Corp//NONSGML PDA Calendar Version 1.0//EN
  VERSION:2.0
  BEGIN:VEVENT
  DTSTAMP:19960704T120000Z
  UID:uid1@example.com
  DTSTART:19960918T143000Z
  END:VEVENT
  END:VCALENDAR
  """

  @event_icalendar_modified """
  BEGIN:VCALENDAR
  PRODID:-//xyz Corp//NONSGML PDA Calendar Version 1.0//EN
  VERSION:2.0
  BEGIN:VEVENT
  DTSTAMP:19960704T120000Z
  UID:uid1@example.com
  DTSTART:19960918T153000Z
  END:VEVENT
  END:VCALENDAR
  """

  setup %{client: client} do
    {:ok, calendar_url} = URL.build_calendar_url(client, @calendar_id)
    on_exit(fn -> CalDAVClient.Calendar.delete(client, calendar_url) end)

    :ok =
      CalDAVClient.Calendar.create(
        client,
        calendar_url,
        name: "Name",
        description: "Description"
      )

    %{calendar_url: calendar_url}
  end

  test "returns correct etag when event is created", %{client: client, calendar_url: calendar_url} do
    {:ok, etag} = client |> CalDAVClient.Event.create(calendar_url, @event_id, @event_icalendar)
    assert {:ok, _icalendar, ^etag} = client |> CalDAVClient.Event.get(calendar_url, @event_id)
  end

  describe "when event is updated" do
    setup %{client: client, calendar_url: calendar_url} do
      {:ok, etag} =
        client |> CalDAVClient.Event.create(calendar_url, @event_id, @event_icalendar)

      [etag: etag]
    end

    test "passes without etag", %{client: client, calendar_url: calendar_url} do
      assert {:ok, _etag} =
               client
               |> CalDAVClient.Event.update(calendar_url, @event_id, @event_icalendar_modified)
    end

    test "passes with correct etag", %{client: client, calendar_url: calendar_url, etag: etag} do
      assert {:ok, _etag} =
               client
               |> CalDAVClient.Event.update(calendar_url, @event_id, @event_icalendar_modified,
                 etag: etag
               )
    end

    test "fails with incorrect etag", %{client: client, calendar_url: calendar_url} do
      assert {:error, %Tesla.Env{status: 412}} =
               client
               |> CalDAVClient.Event.update(calendar_url, @event_id, @event_icalendar_modified,
                 etag: "bad"
               )
    end

    test "returns correct etag when event is updated", %{
      client: client,
      calendar_url: calendar_url,
      etag: etag
    } do
      {:ok, etag} =
        client
        |> CalDAVClient.Event.update(calendar_url, @event_id, @event_icalendar_modified,
          etag: etag
        )

      assert {:ok, _icalendar, ^etag} = client |> CalDAVClient.Event.get(calendar_url, @event_id)
    end
  end

  describe "when event is deleted" do
    setup %{client: client, calendar_url: calendar_url} do
      {:ok, etag} =
        client |> CalDAVClient.Event.create(calendar_url, @event_id, @event_icalendar)

      [etag: etag]
    end

    test "passes without etag", %{client: client, calendar_url: calendar_url} do
      assert :ok = client |> CalDAVClient.Event.delete(calendar_url, @event_id)
    end

    test "passes with correct etag", %{client: client, calendar_url: calendar_url, etag: etag} do
      assert :ok =
               client |> CalDAVClient.Event.delete(calendar_url, @event_id, etag: etag)
    end

    test "fails with incorrect etag", %{client: client, calendar_url: calendar_url} do
      assert {:error, %Tesla.Env{status: 412}} =
               client |> CalDAVClient.Event.delete(calendar_url, @event_id, etag: "bad")
    end
  end
end
