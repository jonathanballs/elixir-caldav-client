defmodule CalDAVClient.XML.Parser do
  @moduledoc """
  Parses XML responses received from the calendar server.
  """

  import SweetXml

  @event_xpath ~x"//*[local-name()='multistatus']/*[local-name()='response']"el
  @url_xpath ~x"./*[local-name()='href']/text()"s
  @icalendar_xpath ~x"./*[local-name()='propstat']/*[local-name()='prop']/*[local-name()='calendar-data']/text()"s
  @etag_xpath ~x"./*[local-name()='propstat']/*[local-name()='prop']/*[local-name()='getetag']/text()"s

  @user_principal_xpath ~x"//*[local-name()='current-user-principal']"el

  @calendar_home_set_xpath ~x"//*[local-name()='calendar-home-set']"el

  @calendar_xpath ~x"//*[local-name()='multistatus']/*[.//*[local-name()='calendar']]"el
  @cal_name_xpath ~x"./*[local-name()='propstat']/*[local-name()='prop']/*[local-name()='displayname']/text()"s
  @cal_type_xpath ~x"./*[local-name()='propstat']/*[local-name()='prop']/*[local-name()='supported-calendar-component-set']/*[local-name()='comp']/@name"s
  @cal_timezone_xpath ~x"./*[local-name()='propstat']/*[local-name()='prop']/*[local-name()='calendar-timezone']/text()"s

  @doc """
  Parses XML response body into a list of events.
  """
  @spec parse_events(response_xml :: String.t()) :: [CalDAVClient.Event.t()]
  def parse_events(response_xml) do
    response_xml
    |> xpath(@event_xpath,
      url: @url_xpath,
      icalendar: @icalendar_xpath,
      etag: @etag_xpath
    )
    |> Enum.map(&struct(CalDAVClient.Event, &1))
  end

  @doc """
  Parses XML response body into a list of calendars.
  """
  @spec parse_calendars(response_xml :: String.t()) :: [CalDAVClient.Calendar.t()]
  def parse_calendars(response_xml) do
    response_xml
    |> xpath(@calendar_xpath,
      url: @url_xpath,
      name: @cal_name_xpath,
      type: @cal_type_xpath,
      timezone: @cal_timezone_xpath
    )
    |> Enum.map(&struct(CalDAVClient.Calendar, &1))
  end

  @doc """
  Parses XML response body into a list of calendars.
  """
  @spec parse_user_principal(response_xml :: String.t()) :: [CalDAVClient.Calendar.t()]
  def parse_user_principal(response_xml) do
    %{href: href} =
      response_xml
      |> xpath(@user_principal_xpath, href: @url_xpath)
      |> hd()

    href
  end

  @doc """
  Parses XML response body into a list of calendars.
  """
  @spec parse_calendar_home_set(response_xml :: String.t()) :: [CalDAVClient.Calendar.t()]
  def parse_calendar_home_set(response_xml) do
    %{href: href} =
      response_xml
      |> xpath(@calendar_home_set_xpath, href: @url_xpath)
      |> hd()

    href
  end
end
