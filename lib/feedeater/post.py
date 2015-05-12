"""Rudimentary Datastore Updater."""
import argparse
import os

import mzgtfs.feed
import transitland.registry
import transitland.entities
import transitland.datastore

import util

def run():
  parser = util.default_parser('Datastore Updater')
  parser.add_argument('--apitoken',
    help='API Token',
    default=os.getenv('TRANSITLAND_DATASTORE_AUTH_TOKEN')
  )
  parser.add_argument("--host",
    help="Datastore Host",
    default=os.getenv('TRANSITLAND_DATASTORE_HOST') or 'http://localhost:3000'
  )
  args = parser.parse_args()
  # 
  r = transitland.registry.FeedRegistry(path=args.registry)
  feedids = args.feedids
  if args.all:
    feedids = r.feeds()
  if len(feedids) == 0:
    raise Exception("No feeds specified! Try --all")    
  #
  for feedid in args.feedids:
    feed = r.feed(feedid)
    gtfsfeed = mzgtfs.feed.Feed(feed.filename())
    feed2 = transitland.entities.Feed.from_gtfs(
      gtfsfeed,
      feedid=feedid
    )
    updater = transitland.datastore.Datastore(
      args.host,
      apitoken=args.apitoken,
      debug=True
    )
    for entity in sorted(feed2.operators(), key=lambda x:x.onestop()):
      updater.update_operator(entity)

if __name__ == "__main__":
  run()