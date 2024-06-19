defmodule CalDAVClient.URLTest do
  use ExUnit.Case
  alias CalDAVClient.URL

  test "join/2" do
    assert URL.merge("/cal.php", "/cal.php/url") == "/cal.php/url"
    assert URL.merge("/cal.php/", "url") == "/cal.php/url"
    assert URL.merge("/cal.php", "url") == "/cal.php/url"
    assert URL.merge("http://example.com/", "url") == "http://example.com/url"
    assert URL.merge("http://example.com", "url") == "http://example.com/url"
  end
end
