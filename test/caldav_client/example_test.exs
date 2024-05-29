defmodule CaldavClient.ExampleTest do
  use ExUnit.Case

  test "test group subject" do
    client = %CalDAVClient.Client{
      server_url: "https://caldav.icloud.com",
      auth: %CalDAVClient.Auth.Basic{
        username: "jonathanballs@protonmail.com",
        password: "mawa-ekqh-cslb-fxhh"
      }
    }

    {:ok, calendars} = CalDAVClient.Calendar.list(client)

    dbg(calendars)

    # Enum.each(calendars, fn calendar ->
    #   CalDAVClient.
    # end)
  end
end
