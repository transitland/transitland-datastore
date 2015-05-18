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

  # Registry
  r = transitland.registry.FeedRegistry(path=args.registry)
  ds = transitland.datastore.Datastore(
    args.host,
    apitoken=args.apitoken,
    debug=args.debug
  )

  # Update datastore.
  feedids = args.feedids or r.feeds()
  for feedid in feedids:
    print "===== Feed: %s ====="%feedid
    infeed = r.feed(feedid)
    filename = args.filename or os.path.join(args.workdir, '%s.zip'%infeed.onestop())
    print "Opening: %s"%filename
    gtfsfeed = mzgtfs.feed.Feed(filename)
    print "Creating Onestop Entities"
    feed = transitland.entities.Feed.from_gtfs(
      gtfsfeed,
      feedid=feedid
    )

    # Similarity search.
    # TODO: If two stops merge into the Onestop ID?
    for o in feed.operators():
      o._cache_onestop()
    for stop in feed.stops():
      print "Similarity: %s"%stop.onestop()
      search_stops = ds.stops(point=stop.point(), radius=1000)   
      s = similarity.CompareEntities(stop, search_stops)
      s.score()
      s.merge(indent='  ')

    # Post changesets.
    for operator in feed.operators():
      print "Updating operator: %s"%operator.onestop()
      entities = sorted(
        operator.stops() | operator.routes(), 
        key=lambda x:x.onestop()
      )
      # Post without relationships
      ds.update_entity(operator, rels=False)
      for entity in entities:
        print "  ... %s"%entity.onestop()
        ds.update_entity(entity, rels=False)
      # Update relationships
      ds.update_entity(operator)
      for entity in entities:
        print "  ... %s"%entity.onestop()
        ds.update_entity(entity)

if __name__ == "__main__":
  run()