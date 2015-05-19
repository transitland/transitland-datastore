"""Fetch Transitland Feed Registry feeds."""
import argparse
import os

import transitland.registry

import util

def run():
  parser = util.default_parser('Fetch Transitland Feed Registry GTFS feeds')
  args = parser.parse_args()

  # Registry
  r = transitland.registry.FeedRegistry(path=args.registry)

  # Download feeds
  newfeeds = []
  feedids = args.feedids or r.feeds()
  for feedid in feedids:
    print "===== Feed: %s ====="%feedid
    feed = r.feed(feedid)
    filename = os.path.join(args.workdir, '%s.zip'%feed.onestop())
    if feed.verify_sha1(filename):
      print "Cached"
    else:
      print "Downloading: %s -> %s"%(feed.url(), filename)
      feed.download(filename, verify=False)
      newfeeds.append(feedid)
    if not feed.verify_sha1(filename):
      print "Warning: Incorrect SHA1 checksum."

  return newfeeds
    
if __name__ == "__main__":
  run()