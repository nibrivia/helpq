from __future__ import print_function
import httplib2
import os

from apiclient import discovery
from oauth2client import client
from oauth2client import tools
from oauth2client.file import Storage

from google.oauth2 import service_account

import csv
import sys

import datetime


lab_calendar = "6.004 Lab hours"
calendar_ids = {}


# If modifying these scopes, delete your previously saved credentials
# at ~/.credentials/calendar-python-quickstart.json
SCOPES = ['https://www.googleapis.com/auth/calendar.readonly',
          'https://www.googleapis.com/auth/calendar']
SERVICE_ACCOUNT_FILE = '/home/nibr/helpq/inst/python/service_secret.json'
APPLICATION_NAME = 'Google Calendar API Python Quickstart'


def get_credentials():
    """Gets valid user credentials from storage.

    If nothing has been stored, or if the stored credentials are invalid,
    the OAuth2 flow is completed to obtain the new credentials.

    Returns:
        Credentials, the obtained credential.
    """
    return service_account.Credentials.from_service_account_file(
      SERVICE_ACCOUNT_FILE, scopes=SCOPES)

def get_calendar_service():
  """Returns a valid GCal service object
  """
  credentials = get_credentials()
  service = discovery.build('calendar', 'v3', credentials=credentials)

  return service

def calendar_list(service):
  existing_calendars = []

  page_token = None
  while True:
    calendar_list = service.calendarList().list(pageToken=page_token).execute()
    for calendar_list_entry in calendar_list['items']:
      existing_calendars.append(calendar_list_entry)

    page_token = calendar_list.get('nextPageToken')
    if not page_token:
      break

  return existing_calendars

def calendar_exists(service, kerberos):
  calendars = calendar_list(service)

  for c in calendars:
    if c['summary'] == kerberos: return True

  return False

def get_staff_calendar_id(service, kerberos):
  if kerberos in calendar_ids:
    return calendar_ids[kerberos]


  if calendar_exists(service, kerberos):
    calendars = calendar_list(service)
    for c in calendars:
      calendar_ids[kerberos] = c['id'] # Add all the calendars, not just ours
      if c['summary'] == kerberos:
        return c['id']
  else:
    calendar = {
      'summary': kerberos,
      'timeZone': 'America/New_York'
    }
    new_calendar = service.calendars().insert(body=calendar).execute()

    # Make calendar publicly readable
    rule = {
      'role' : "reader",
      'scope' : {
        'type': 'default'
      }
    }
    service.acl().insert(calendarId=new_calendar['id'], body = rule).execute()

    calendar_ids[kerberos] = new_calendar['id']
    return new_calendar['id']


def lab_hours_add(service, kerberos, begin, end):
  event = {
    'summary': kerberos + " lab hours",
    'location': '32-083',
    'visibility': 'public',
    'start': {
      'dateTime': begin,
      'timeZone': 'America/New_York',
    },
    'end': {
      'dateTime': end,
      'timeZone': 'America/New_York',
    },
    'attendees': [
      {'email': kerberos + '@mit.edu'},
    ],
    'reminders': {
      'useDefault': True,
      'overrides': [
      ],
    },
  }

  ## Add to the staff's calendar
  cal_id = get_staff_calendar_id(service, kerberos)
  print("")
  print("Adding lab hours for ", kerberos, ": ", begin, " -> ", end, " (ind cal)")
  event = service.events().insert(calendarId=cal_id, body=event).execute()

  ## Add to the general calendar
  lab_id  = get_staff_calendar_id(service, "6.004 Lab hours")
  event['summary'] = kerberos

  print("Adding lab hours for ", kerberos, ": ", begin, " -> ", end, " (lab cal)")
  event = service.events().insert(calendarId=lab_id, body=event).execute()




def lab_hours_remove(service, kerberos, begin, end):
  lab_id  = get_staff_calendar_id(service, lab_calendar)

  # Remove from staff's calendar
  cal_id = get_staff_calendar_id(service, kerberos)
  events = get_lab_hours(service, kerberos)
  print("")
  print("Removing lab hours for ", kerberos, ": ", begin, " -> ", end)

  for e in events:
    if e['start']['dateTime'] == begin and e['end']['dateTime'] == end:
      service.events().delete(calendarId=cal_id, eventId = e['id']).execute()
      print("Removed lab hours for ", kerberos, ": ", begin, " -> ", end, " (ind cal)")

  # Remove from lab's calendar
  cal_id = get_staff_calendar_id(service, lab_calendar)
  events = get_lab_hours(service, lab_calendar)

  for e in events:
    if kerberos in e['summary'] and e['start']['dateTime'] == begin and e['end']['dateTime'] == end:
      service.events().delete(calendarId=lab_id, eventId = e['id']).execute()
      print("Removed lab hours for ", kerberos, ": ", begin, " -> ", end, " (lab cal)")




def get_lab_hours(service, kerberos):
  cal_id = get_staff_calendar_id(service, kerberos)

  page_token = None
  events = []
  while True:
    page = service.events().list(calendarId=cal_id, pageToken=page_token).execute()
    page_token = page.get('nextPageToken')

    # print('a')
    # print(events)
    events.extend(page['items'])
    # print(events)
    # print('')
    if not page_token:
      break

  # print(kerberos + " events")
  # for e in events:
  #   print(e)
  #   print("")
  # print("")
  # print("")

  return events




def main():
  """Shows basic usage of the Google Calendar API.

  Creates a Google Calendar API service object and outputs a list of the next
  10 events on the user's calendar.
  """
  service = get_calendar_service()
  kerberoi = ["nibr", "6.004 Lab hours", "helik"]

  print("Calendars")
  cs = sorted(calendar_list(service), key = lambda x: x['summary'])
  for c in cs: print(c['summary'], "https://calendar.google.com/calendar/embed?src="+ c['id'])
  print("")


  # print("Events")
  # for k in kerberoi:
  #   print(" ", k)
  #   events = get_lab_hours(service, k)
  #   for e in events:
  #     print('  - id', e['id'])
  #     print('  - title', e['summary'])
  #     print('  - begin ', str(e['start']))
  #     print('  - finish',   str(e['end']))
  #     # service.events().delete(calendarId=lab_id, eventId = e['id']).execute()
  #   print("")




  # lab_hours_add("nibr", "2018-03-08T12:00:00-0500", "2018-03-08T13:00:00-0500")
  # print("")
  # print("----")
  # print("ACL")

  # rule = {
    # 'role' : "reader",
    # 'scope' : {
      # 'type': 'default'
    # }
  # }
  # service.acl().insert(calendarId=nibr_id, body = rule).execute()
  # service.acl().insert(calendarId= lab_id, body = rule).execute()
  # acl = service.acl().list(calendarId=nibr_id).execute()
  # for r in acl: print(r, acl[r])

  # acl = service.acl().list(calendarId= lab_id).execute()
  # for r in acl: print(r, acl[r])




if __name__ == '__main__':
  main()
  service = get_calendar_service()
  for row in csv.reader(iter(sys.stdin.readline, '')):
    action, kerberos, start, end = row

    start = start[:-2] + ":" + start[-2:]
    end   =   end[:-2] + ":" +   end[-2:]

    if action == "add":
      lab_hours_add(service, kerberos, start, end)
    elif action == "remove":
      lab_hours_remove(service, kerberos, start, end)
    else:
      print("idk what to do here")
      break

