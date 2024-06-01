defmodule CaldavClient.ExampleTest do
  use ExUnit.Case
  @moduletag :integration

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
  end
end
