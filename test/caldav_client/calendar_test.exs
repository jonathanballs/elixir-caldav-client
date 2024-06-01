defmodule CalDAVClient.CalendarTest do
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

  @calendar_id "calendar_test"

  setup do
    {:ok, calendar_url} = URL.build_calendar_url(@client, @calendar_id)
    on_exit(fn -> @client |> CalDAVClient.Calendar.delete(calendar_url) end)
    :ok
  end

  describe "when calendar does not exist" do
    test "returns ok on calendar create" do
      assert :ok =
               @client
               |> CalDAVClient.Calendar.create(@calendar_id,
                 name: "Name",
                 description: "Description"
               )
    end

    test "returns error not found on calendar update" do
      assert {:error, :not_found} = @client |> CalDAVClient.Calendar.update(@calendar_id)
    end

    test "returns error not found on calendar delete" do
      assert {:error, :not_found} = @client |> CalDAVClient.Calendar.delete(@calendar_id)
    end
  end

  describe "when calendar exists" do
    setup do
      :ok =
        @client
        |> CalDAVClient.Calendar.create(@calendar_id, name: "Name", description: "Description")

      :ok
    end

    test "returns error already exists on calendar create" do
      assert {:error, :already_exists} =
               @client
               |> CalDAVClient.Calendar.create(@calendar_id,
                 name: "Name",
                 description: "Description"
               )
    end

    test "returns ok on calendar update" do
      assert :ok =
               @client
               |> CalDAVClient.Calendar.update(@calendar_id,
                 name: "Name2",
                 description: "Description2"
               )
    end

    test "returns ok on calendar delete" do
      assert :ok = @client |> CalDAVClient.Calendar.delete(@calendar_id)
    end
  end

  describe "lists calendars" do
    test "returns list of calendars" do
      {:ok, [calendar]} =
        @client
        |> CalDAVClient.Calendar.list()

      assert %CalDAVClient.Calendar{
               url: "/cal.php/calendars/test@example.com/default/",
               name: "Default calendar",
               type: "VEVENTVTODO",
               timezone: "Europe/London",
               color: "",
               description: "Default calendar"
             } = calendar
    end
  end
end
