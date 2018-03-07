from __future__ import print_function
import httplib2
import os

from apiclient import discovery
from oauth2client import client
from oauth2client import tools
from oauth2client.file import Storage

from google.oauth2 import service_account


import datetime

try:
    import argparse
    flags = argparse.ArgumentParser(parents=[tools.argparser]).parse_args()
except ImportError:
    flags = None

# If modifying these scopes, delete your previously saved credentials
# at ~/.credentials/calendar-python-quickstart.json
SCOPES = ['https://www.googleapis.com/auth/calendar.readonly',
          'https://www.googleapis.com/auth/calendar']
SERVICE_ACCOUNT_FILE = 'service_secret.json'
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
  if calendar_exists(service, kerberos):
    calendars = calendar_list(service)
    for c in calendars:
      if c['summary'] == kerberos: return c['id']
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

    return new_calendar['id']


def update_lab_hours(kerberos, begin, end):
  service = get_calendar_service()

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
  event = service.events().insert(calendarId=cal_id, body=event).execute()

  ## Add to the general calendar
  lab_id  = get_staff_calendar_id(service, "6.004 Lab hours")
  event = service.events().insert(calendarId=lab_id, body=event).execute()

  print('Event created: %s' % (event.get('htmlLink')))

def main():
  """Shows basic usage of the Google Calendar API.

  Creates a Google Calendar API service object and outputs a list of the next
  10 events on the user's calendar.
  """
  service = get_calendar_service()

  cals = calendar_list(service)
  for c in cals: print(c['summary'], c['id'])

  print("")
  nibr_id = get_staff_calendar_id(service, "nibr")
  lab_id  = get_staff_calendar_id(service, "6.004 Lab hours")

  cals = calendar_list(service)
  for c in cals: print(c['summary'], c['id'])

  print("")
  print("----")
  print("ACL")

  rule = {
    'role' : "reader",
    'scope' : {
      'type': 'default'
    }
  }
  service.acl().insert(calendarId=nibr_id, body = rule).execute()
  service.acl().insert(calendarId= lab_id, body = rule).execute()
  acl = service.acl().list(calendarId=nibr_id).execute()
  for r in acl: print(r, acl[r])

  acl = service.acl().list(calendarId= lab_id).execute()
  for r in acl: print(r, acl[r])

  update_lab_hours("nibr", "2018-03-08T12:00:00-0500", "2018-03-08T13:00:00-0500")



if __name__ == '__main__':
    main()
