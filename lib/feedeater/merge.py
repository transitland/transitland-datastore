"""Fetch Transitland Feed Registry feeds."""
import argparse

import transitland.registry

import util

def run():
  parser = util.default_parser('Merge Onestop/OSM Way into GTFS tables')
  args = parser.parse_args()
  # Do Stuff
    
if __name__ == "__main__":
  run()