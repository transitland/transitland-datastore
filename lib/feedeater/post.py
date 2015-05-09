"""Rudimentary Datastore Updater."""
import argparse
import os

import mzgtfs.feed
import transitland.registry
import transitland.entities
import transitland.datastore

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
  # Do Stuff
  # onestopregistry = onestop.registry.OnestopRegistry(args.onestop)
  # for filename in args.filenames:
  #   print "===== %s: %s ====="%(args.feedid, filename)
  #   feed = mzgtfs.feed.Feed(filename)
  #   onestopfeed = onestop.entities.OnestopFeed.from_gtfs(feed, feedid=args.feedid)
  #   updater = datastore.DatastoreUpdater(
  #     args.host,
  #     apitoken=args.apitoken,
  #     debug=args.debug
  #   )
  #   for entity in sorted(onestopfeed.stops(), key=lambda x:x.onestop()):
  #     updater.merge_entity(entity)

if __name__ == "__main__":
  run()