#!/usr/bin/env python

# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

"""
An example to show receiving events from an Event Hub partition.
Use this to make sure that the eventhub is receiving data.
"""
import os
import sys
import logging
import time
import json
from azure.eventhub import EventHubClient, Receiver, Offset

# import examples
# logger = examples.get_logger(logging.INFO)

# Note: Address can be in either of these formats:
# "amqps://<URL-encoded-SAS-policy>:<URL-encoded-SAS-key>@<mynamespace>.servicebus.windows.net/myeventhub"
# "amqps://<mynamespace>.servicebus.windows.net/myeventhub"

ADDRESS_URL = ""
ACCESS_POLICY = ""
ACCESS_KEY = ""

try:
  with open('./conf/ehrecv.conf') as json_data:
    d = json.load(json_data)
    ADDRESS_URL =  d['EH_ADDRESS_URL']
    ACCESS_POLICY = d['EH_ACCESS_POLICY']
    ACCESS_KEY = d['EH_ACCESS_KEY']
    print("values: Address: ({}), Policy: ({}), Key: ({})".format(ADDRESS_URL, ACCESS_POLICY, ACCESS_KEY))
except IOExcept as error:
  print("These values must be set: EH_ADDRESS_URL, EH_ACCESS_POLICY, EH_ACCESS_KEY.")
  print("  EH_ADDRESS_URL:      Event Hub URL, e.g., myevents223.servicebus.windows.net/myhub")
  print("  EH_ACCESS_POLICY:    The name of a SAS policy for your hub, i.e., read_securityevents")
  print( "  EH_ACCESS_KEY:       The base64 encoded key value for your SAS policy")
  print("These values can all be retrieved from the Azure portal or CLI.")
  print("To create this configuration, copy ehrecv.conf to ehrecv.conf.secure")
  sys.exit(1)  

# Use these defaults unless there is a need to change them
CONSUMER_GROUP = "$default"
OFFSET = Offset("-1")
PARTITION = "0"

total = 0
last_sn = -1
last_offset = "-1"
client = EventHubClient(ADDRESS_URL, debug=False, username=ACCESS_POLICY, password=ACCESS_KEY)
try:
  receiver = client.add_receiver(CONSUMER_GROUP, PARTITION, prefetch=5000, offset=OFFSET)
  client.run()
  start_time = time.time()
  batch = receiver.receive(timeout=5000)
  while batch:
    for event_data in batch:
      last_offset = event_data.offset
      last_sn = event_data.sequence_number
      print("Received: {}, {}".format(last_offset.value, last_sn))
      print(event_data.body_as_str())
      total += 1
  batch = receiver.receive(timeout=5000)

  end_time = time.time()
  client.stop()
  run_time = end_time - start_time
  print("Received {} messages in {} seconds".format(total, run_time))

except KeyboardInterrupt:
  pass
finally:
  client.stop()
