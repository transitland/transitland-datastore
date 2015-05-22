"""Fetch Transitland Feed Registry feeds."""
import argparse
import os
import collections

import mzgtfs.feed

import util
import task
# Temporary:
import tyr

class FeedEaterArtifact(task.FeedEaterTask):
  def run(self):
    # Create GTFS Artifacts
    print "===== Feed: %s ====="%self.feedid
    feed = self.registry.feed(self.feedid)
    filename = self.filename or os.path.join(self.workdir, '%s.zip'%feed.onestop())
    print "Opening: %s"%filename
    gtfsfeed = mzgtfs.feed.Feed(filename, debug=self.debug)

    for stop in gtfsfeed.stops():
      identifier = stop.feedid(self.feedid)
      print "Looking for identifier: %s"%identifier
      found = self.datastore.stops(identifier=identifier)
      if not found:
        print "  No identifier found!"
        stop.set('onestop_id', None)
        stop.set('osm_way_id', None)
        continue
      match = sorted(found, key=lambda x:x.data['updated_at'])[0]
      onestop_id = match.onestop()
      osm_way_id = match.data.get('osm_way_id')
      if not osm_way_id and tyr:
        osm_way_id = tyr.tyr_osm(
          stop, 
          apitoken=os.getenv('TYR_AUTH_TOKEN'), 
          debug=self.debug
        )
        print "  ... got tyr osm_way_id:", osm_way_id
      print "  onestop_id: %s, osm_way_id: %s"%(onestop_id, osm_way_id)
      stop.set('onestop_id', onestop_id)
      stop.set('osm_way_id', osm_way_id)

    # Write output
    stopstxt = os.path.join(self.workdir, 'stops.txt')
    artifact = os.path.join(self.workdir, '%s.artifact.zip'%feed.onestop())
    if os.path.exists(stopstxt):
      os.unlink(stopstxt)
    if os.path.exists(artifact):
      os.unlink(artifact)    
    #
    print "Creating output artifact: %s"%artifact
    gtfsfeed.write(stopstxt, gtfsfeed.stops(), sortkey='stop_id')
    gtfsfeed.make_zip(artifact, files=[stopstxt], clone=filename)
    #
    if os.path.exists(stopstxt):
      os.unlink(stopstxt)
    
if __name__ == "__main__":
  task = FeedEaterArtifact.from_args()
  task.run()
