defmodule CalDAVClient.IntegrationTest do
  @moduledoc """
  This module defines the test case to be used by tests that require setting up
  a connection with the baikal server
  """
  use ExUnit.CaseTemplate

  @server_url Application.compile_env(:caldav_client, :test_server)[:server_url]
  @username Application.compile_env(:caldav_client, :test_server)[:username]
  @password Application.compile_env(:caldav_client, :test_server)[:password]

  using do
    quote do
      @moduletag :integration
    end
  end

  setup do
    client = %CalDAVClient.Client{
      server_url: @server_url,
      auth: %CalDAVClient.Auth.Basic{
        username: @username,
        password: @password
      }
    }

    invalid_client = %CalDAVClient.Client{
      server_url: @server_url,
      auth: %CalDAVClient.Auth.Basic{
        username: "foo",
        password: "bar"
      }
    }

    %{client: client, invalid_client: invalid_client}
  end
end
