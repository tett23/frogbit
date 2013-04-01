#!/usr/bin/env python3.1
import sys
from itertools import dropwhile

from ariblib import TransportStreamFile
from ariblib.packet import pid

output = open(sys.argv[2], 'wb')
with TransportStreamFile(sys.argv[1]) as ts:
  video_pid = ts.get_video_pid(1)
  for packet in dropwhile(lambda p: pid(p) == video_pid, ts):
    output.write(packet)
