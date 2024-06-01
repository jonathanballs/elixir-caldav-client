defmodule CalDAVClient.EventTest do
  use ExUnit.Case

  alias CalDAVClient.URL

  @moduletag :integration

  @server_url Application.compile_env(:caldav_client, :test_server)[:server_url]
  @username Application.compile_env(:caldav_client, :test_server)[:username]
  @password Application.compile_env(:caldav_client, :test_server)[:password]

  @client %CalDAVClient.Client{
    server_url: @server_url,
    auth: %CalDAVClient.Auth.Basic{
      username: @username,
      password: @password
    }
  }

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

  setup do
    {:ok, calendar_url} = URL.build_calendar_url(@client, @calendar_id)
    on_exit(fn -> @client |> CalDAVClient.Calendar.delete(calendar_url) end)
    :ok
  end

  describe "when calendar does not exist" do
    test "returns error on event create" do
      assert {:error, :not_found} =
               @client |> CalDAVClient.Event.create(@calendar_id, @event_id, @event_icalendar)
    end

    test "returns error on event update" do
      assert {:error, :not_found} =
               @client |> CalDAVClient.Event.update(@calendar_id, @event_id, @event_icalendar)
    end

    test "returns error on event delete" do
      assert {:error, :not_found} = @client |> CalDAVClient.Event.delete(@calendar_id, @event_id)
    end

    test "returns error on event get" do
      assert {:error, :not_found} = @client |> CalDAVClient.Event.get(@calendar_id, @event_id)
    end

    test "returns error on event find by UID" do
      assert {:error, :not_found} =
               @client |> CalDAVClient.Event.find_by_uid(@calendar_id, @event_uid)
    end

    test "returns error on get events" do
      assert {:error, :not_found} =
               @client |> CalDAVClient.Event.get_events(@calendar_id, @from, @to)
    end
  end

  describe "when calendar exists but event does not exist" do
    setup do
      :ok =
        @client
        |> CalDAVClient.Calendar.create(@calendar_id, name: "Name", description: "Description")

      :ok
    end

    test "returns ok on event create" do
      assert {:ok, _etag} =
               @client |> CalDAVClient.Event.create(@calendar_id, @event_id, @event_icalendar)
    end

    test "returns error on event create when DTSTART is missing" do
      assert {:error, _reason} =
               @client
               |> CalDAVClient.Event.create(
                 @calendar_id,
                 @event_id,
                 @event_icalendar_missing_dtstart
               )
    end

    test "returns unsupported media type error when icalendar malformed" do
      assert {:error, :unsupported_media_type} =
               @client
               |> CalDAVClient.Event.create(
                 @calendar_id,
                 @event_id,
                 @event_icalendar_malformed_icalendar
               )
    end

    test "returns error not found on event delete" do
      assert {:error, :not_found} = @client |> CalDAVClient.Event.delete(@calendar_id, @event_id)
    end

    test "returns error on event get" do
      assert {:error, :not_found} = @client |> CalDAVClient.Event.get(@calendar_id, @event_id)
    end

    test "returns error on event find by UID" do
      assert {:error, :not_found} =
               @client |> CalDAVClient.Event.find_by_uid(@calendar_id, @event_uid)
    end

    test "returns empty list on get events" do
      assert {:ok, []} = @client |> CalDAVClient.Event.get_events(@calendar_id, @from, @to)
    end
  end

  describe "when both calendar and event exist" do
    setup do
      :ok =
        @client
        |> CalDAVClient.Calendar.create(@calendar_id, name: "Name", description: "Description")

      {:ok, _etag} =
        @client |> CalDAVClient.Event.create(@calendar_id, @event_id, @event_icalendar)

      :ok
    end

    test "returns error already exists on event create" do
      assert {:error, :already_exists} =
               @client |> CalDAVClient.Event.create(@calendar_id, @event_id, @event_icalendar)
    end

    test "returns ok on event update" do
      assert {:ok, _etag} =
               @client |> CalDAVClient.Event.update(@calendar_id, @event_id, @event_icalendar)
    end

    test "returns ok on event delete" do
      assert :ok = @client |> CalDAVClient.Event.delete(@calendar_id, @event_id)
    end

    test "returns ok on event get" do
      assert {:ok, @event_icalendar, _etag} =
               @client |> CalDAVClient.Event.get(@calendar_id, @event_id)
    end

    test "returns ok on event find by UID" do
      assert {:ok, %CalDAVClient.Event{icalendar: @event_icalendar}} =
               @client |> CalDAVClient.Event.find_by_uid(@calendar_id, @event_uid)
    end

    test "returns list with single event on get events" do
      assert {:ok, [%CalDAVClient.Event{icalendar: @event_icalendar}]} =
               @client |> CalDAVClient.Event.get_events(@calendar_id, @from, @to, expand: false)
    end
  end
end
