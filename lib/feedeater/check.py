"""Check Transitland Feed Registry GTFS feeds for updates."""
import argparse
import os

import transitland.registry

import util

def run():
  parser = util.default_parser('Check Transitland Feed Registry GTFS feeds for updates.')
  args = parser.parse_args()
  # Registry
  r = transitland.registry.FeedRegistry(path=args.registry)
  # Check feeds
  newfeeds = []
  feedids = args.feedids or r.feeds()
  for feedid in feedids:
    feed = r.feed(feedid)
    filename = os.path.join(args.workdir, '%s.zip'%feed.onestop())
    if feed.verify_sha1(filename):
      pass
    else:
      newfeeds.append(feedid)
  return newfeeds
    
if __name__ == "__main__":
  newfeeds = run()
  print " ".join(newfeeds)