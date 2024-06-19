defmodule CalDAVClient.CalendarTest do
  use CalDAVClient.IntegrationTest

  alias CalDAVClient.URL

  @calendar_id "calendar_test"

  setup %{client: client} do
    {:ok, calendar_url} = URL.build_calendar_url(client, @calendar_id)
    on_exit(fn -> CalDAVClient.Calendar.delete(client, calendar_url) end)

    %{calendar_url: calendar_url}
  end

  describe "when calendar does not exist" do
    test "returns ok on calendar create", %{client: client} do
      assert :ok =
               client
               |> CalDAVClient.Calendar.create(@calendar_id,
                 name: "Name",
                 description: "Description"
               )
    end

    test "returns error not found on calendar update", %{
      client: client,
      calendar_url: calendar_url
    } do
      assert {:error, %Tesla.Env{status: 404}} =
               CalDAVClient.Calendar.update(client, calendar_url)
    end

    test "returns error not found on calendar delete", %{
      client: client,
      calendar_url: calendar_url
    } do
      assert {:error, %Tesla.Env{status: 404}} =
               client |> CalDAVClient.Calendar.delete(calendar_url)
    end
  end

  describe "when calendar exists" do
    setup %{client: client} do
      :ok =
        CalDAVClient.Calendar.create(
          client,
          @calendar_id,
          name: "Name",
          description: "Description"
        )
    end

    test "returns error already exists on calendar create", %{
      client: client
    } do
      assert {:error, %Tesla.Env{status: 405}} =
               client
               |> CalDAVClient.Calendar.create(@calendar_id,
                 name: "Name",
                 description: "Description"
               )
    end

    test "returns ok on calendar update", %{client: client, calendar_url: calendar_url} do
      assert :ok =
               client
               |> CalDAVClient.Calendar.update(calendar_url,
                 name: "Name2",
                 description: "Description2"
               )
    end

    test "returns ok on calendar delete", %{client: client, calendar_url: calendar_url} do
      assert :ok = client |> CalDAVClient.Calendar.delete(calendar_url)
    end

    test "returns list of calendars", %{client: client, calendar_url: calendar_url} do
      {:ok, [calendar]} =
        client
        |> CalDAVClient.Calendar.list()

      assert %CalDAVClient.Calendar{
               url: ^calendar_url,
               name: "Name",
               type: "VEVENT",
               timezone: "",
               color: "",
               description: "Description"
             } = calendar
    end
  end

  describe "invalid client" do
    test "returns 401 errors", %{invalid_client: client} do
      assert {:error, %Tesla.Env{status: 401}} = CalDAVClient.Calendar.list(client)

      assert {:error, %Tesla.Env{status: 401}} =
               CalDAVClient.Calendar.create(
                 client,
                 @calendar_id,
                 name: "Name",
                 description: "Description"
               )
    end
  end
end
