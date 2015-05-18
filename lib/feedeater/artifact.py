"""Fetch Transitland Feed Registry feeds."""
import argparse
import os
import collections

import mzgtfs.feed
import transitland.registry
import transitland.datastore

import util
# Temporary:
import tyr

def tyr_osm(stop, apitoken=None):
  if not tyr:
    return None
  t = tyr.TYR('http://valhalla.api.dev.mapzen.com', apitoken=apitoken, debug=True)
  response = t.locate([stop.point()])
  try:
    assert response
    assert response[0]['ways']
  except:
    print "No matching OSM Way ID for stop."
    return None
  ways = collections.defaultdict(list)
  for way in response[0]['ways']:
    d = util.haversine(stop.point(), (way['correlated_lon'], way['correlated_lat']))
    ways[d].append(way['way_id'])
  # get the lowest way_id in the closest way.
  way_id = sorted(ways[sorted(ways.keys())[0]])[0]
  return way_id

def run():
  parser = util.default_parser('Merge Onestop/OSM Way into GTFS tables')
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

  # Create GTFS Artifacts
  feedids = args.feedids or r.feeds()
  for feedid in feedids:
    print "===== Feed: %s ====="%feedid
    infeed = r.feed(feedid)
    filename = args.filename or os.path.join(args.workdir, '%s.zip'%feedid)
    print "Opening: %s"%filename
    gtfsfeed = mzgtfs.feed.Feed(filename, debug=args.debug)

    for stop in gtfsfeed.stops():
      identifier = stop.feedid(feedid)
      print "Looking for identifier: %s"%identifier
      found = ds.stops(identifier=identifier)
      if not found:
        print "  No identifier found!"
        stop.set('onestop_id', None)
        stop.set('osm_way_id', None)
        continue
      match = sorted(found, key=lambda x:x.data['updated_at'])[0]
      onestop_id = match.onestop()
      osm_way_id = match.data.get('osm_way_id')
      if not osm_way_id and tyr:
        osm_way_id = tyr_osm(stop, apitoken=os.getenv('TYR_AUTH_TOKEN'))
        print "  ... got tyr osm_way_id:", osm_way_id
      print "  onestop_id: %s, osm_way_id: %s"%(onestop_id, osm_way_id)
      stop.set('onestop_id', onestop_id)
      stop.set('osm_way_id', osm_way_id)

    # Write output
    stopstxt = 'stops.txt'
    artifact = '%s.artifact.zip'%feedid 
    if os.path.exists(stopstxt):
      os.unlink(stopstxt)
    if os.path.exists(artifact):
      os.path.unlink(artifact)    
    #
    print "Creating output artifact: %s"%artifact
    gtfsfeed.write(stopstxt, gtfsfeed.stops(), sortkey='stop_id')
    gtfsfeed.make_zip(artifact, files=[stopstxt], clone=filename)
    #
    if os.path.exists(stopstxt):
      os.unlink(stopstxt)
    
if __name__ == "__main__":
  run()