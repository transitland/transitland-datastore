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
  def __init__(self, *args, **kwargs):
    super(FeedEaterArtifact, self).__init__(*args, **kwargs)
    self.tyrhost = kwargs.get('tyrhost')
    self.tyrtoken = kwargs.get('tyrtoken')

  def parser(self):
    parser = super(FeedEaterArtifact, self).parser()
    parser.add_argument(
      '--tyrtoken',
      help='TYR api token',
      default=os.getenv('TYR_AUTH_TOKEN')
    )
    parser.add_argument(
      '--tyrhost',
      help='TYR Host',
      default=os.getenv('TYR_HOST') or 'https://valhalla.mapzen.com'
    )      
    return parser
  
  def run(self):
    # Create GTFS Artifacts
    self.log("===== Feed: %s ====="%self.feedid)
    feed = self.registry.feed(self.feedid)
    filename = self.filename or os.path.join(self.workdir, '%s.zip'%feed.onestop())
    self.log("Opening: %s"%filename)
    gtfsfeed = mzgtfs.feed.Feed(filename)

    for stop in gtfsfeed.stops():
      identifier = stop.feedid(self.feedid)
      self.log("Looking for identifier: %s"%identifier)
      found = self.datastore.stops(identifier=identifier)
      if not found:
        self.log("  No identifier found!")
        stop.set('onestop_id', None)
        stop.set('osm_way_id', None)
        continue
      match = sorted(found, key=lambda x:x.data['updated_at'])[0]
      onestop_id = match.onestop()
      osm_way_id = match.data.get('osm_way_id')
      if not osm_way_id and tyr:
        osm_way_id = tyr.tyr_osm(
          stop,
          endpoint=self.tyrhost,
          apitoken=self.tyrtoken
        )
        self.log("  ... got tyr osm_way_id: %s"%osm_way_id)
      self.log("  onestop_id: %s, osm_way_id: %s"%(onestop_id, osm_way_id))
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
    self.log("Creating output artifact: %s"%artifact)
    gtfsfeed.write(stopstxt, gtfsfeed.stops(), sortkey='stop_id')
    gtfsfeed.make_zip(artifact, files=[stopstxt], clone=filename)
    #
    if os.path.exists(stopstxt):
      os.unlink(stopstxt)
    
if __name__ == "__main__":
  task = FeedEaterArtifact.from_args()
  task.run()
