"""Fetch Transitland Feed Registry feeds."""
import argparse

import transitland.registry

import util

def run():
  parser = util.default_parser('Fetch Transitland Feed Registry GTFS feeds')
  args = parser.parse_args()
  r = transitland.registry.FeedRegistry(path=args.registry)
  feedids = args.feedids
  if args.all:
    feedids = r.feeds()
  if len(feedids) == 0:
    raise Exception("No feeds specified! Try --all")
  for feedid in feedids:
    feed = r.feed(feedid)
    if feed.download_check_cache():
      print "Cached:", feed.filename()
    else:
      print "Downloading:", feed.url(), "->", feed.filename()
      result = feed.download()
    
if __name__ == "__main__":
  run()