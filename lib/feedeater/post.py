"""Datastore Updater."""
import os

import mzgtfs.feed
import transitland.entities

import similarity
import util
import task

class FeedEaterPost(task.FeedEaterTask):
  def run(self):
    # Update datastore.
    print "===== Feed: %s ====="%self.feedid
    infeed = self.registry.feed(self.feedid)
    filename = self.filename or os.path.join(self.workdir, '%s.zip'%infeed.onestop())
    print "Opening: %s"%filename
    gtfsfeed = mzgtfs.feed.Feed(filename)
    print "Creating Onestop Entities"
    feed = transitland.entities.Feed.from_gtfs(
      gtfsfeed,
      feedid=self.feedid
    )

    # Similarity search.
    # TODO: If two stops merge into the Onestop ID?
    for o in feed.operators():
      o._cache_onestop()
    for stop in feed.stops():
      print "Similarity: %s"%stop.onestop()
      search_stops = self.datastore.stops(point=stop.point(), radius=1000)   
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
      self.datastore.update_entity(operator, rels=False)
      for entity in entities:
        print "  ... %s"%entity.onestop()
        self.datastore.update_entity(entity, rels=False)
      # Update relationships
      self.datastore.update_entity(operator)
      for entity in entities:
        print "  ... %s"%entity.onestop()
        self.datastore.update_entity(entity)

if __name__ == "__main__":
  task = FeedEaterPost.from_args()
  task.run()
