"""Fetch Transitland Feed Registry feeds."""
import argparse
import os

import transitland.registry

import util

def run():
  parser = util.default_parser('Fetch Transitland Feed Registry GTFS feeds')
  parser.add_argument(
    '--noverify', 
    action='store_true',
    help='Do not verify downloaded feed checksums', 
  )
  args = parser.parse_args()
  #
  r = transitland.registry.FeedRegistry(path=args.registry)
  feedids = args.feedids
  if args.all:
    feedids = sorted(r.feeds())
  if len(feedids) == 0:
    raise Exception("No feeds specified! Try --all")
  #
  for feedid in feedids:
    print feedid
    feed = r.feed(feedid)
    filename = os.path.join(args.workdir, '%s.zip'%feed.onestop())
    feed.download(filename=filename, verify=(not args.noverify))
    
if __name__ == "__main__":
  run()