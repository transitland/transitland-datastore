"""Rudimentary Datastore Updater."""
import argparse
import os

import mzgtfs.feed
import transitland.registry
import transitland.entities
import transitland.datastore

import similarity
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
    infeed = r.feed(feedid)
    filename = args.filename or os.path.join(args.workdir, '%s.zip'%infeed.onestop())
    gtfsfeed = mzgtfs.feed.Feed(filename)
    feed = transitland.entities.Feed.from_gtfs(
      gtfsfeed,
      feedid=feedid
    )
    updater = transitland.datastore.Datastore(
      args.host,
      apitoken=args.apitoken,
      debug=args.debug
    )
    # TODO:
    # If two stops merge into the Onestop ID?
    for stop in feed.stops():
      search_stops = updater.stops(point=stop.point(), radius=1000)      
      s = similarity.CompareEntities(stop, search_stops)
      s.score()
      s.merge()
    # update with the merged entity...
    for operator in feed.operators():
      entities = operator.stops() # | operator.routes()
      # Note: Agencies must be created before routes/stops.
      # Post without relationships
      updater.update_entity(operator, rels=False)
      for entity in entities:
        updater.update_entity(entity, rels=False)
      # Update relationships
      updater.update_entity(operator)
      for entity in entities:
        updater.update_entity(entity)

if __name__ == "__main__":
  run()