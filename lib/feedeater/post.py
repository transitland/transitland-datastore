"""Datastore Updater."""
import os

import mzgtfs.feed
import transitland.entities

import similarity
import task
import util

class FeedEaterPost(task.FeedEaterTask):
  def run(self):
    # Update datastore.
    self.log("===== Feed: %s ====="%self.feedid)
    feed = self.registry.feed(self.feedid)
    filename = self.filename or os.path.join(self.workdir, '%s.zip'%feed.onestop())
    self.log("Opening: %s"%filename)
    gtfsfeed = mzgtfs.feed.Feed(filename)
    self.log("Creating Onestop Entities")
    feed.load_gtfs(gtfsfeed, populate=False)
    if not feed.operators():
      self.log("No matching operators specified in the feed registry entry. Nothing to do.")
      return

    # Similarity search.
    for o in feed.operators():
      o._cache_onestop()

    # Compare against datastore entities and merge if possible.
    for stop in feed.stops():
      self.datastore_merge(stop)
      
    # Post changesets.
    self.log("Updating feed: %s"%feed.onestop())
    self.update_feed(feed)
    self.log("Done")      
    self.log("Finished!")
  
  def datastore_merge(self, entity, threshold=0.5):
    self.log("Looking for entity: %s"%entity.onestop())
    search_entities = self.datastore.stops(point=entity.point(), radius=100)
    s = similarity.MatchEntities(entity, search_entities)
    s.score()
    best = s.best()
    self.log("    %s: %s"%(entity.onestop(), entity.name()))
    if not best.match:
      self.log(" -> No result")
    elif entity.onestop() == best.match.onestop():
      self.log(" -> %s: %s"%(best.match.onestop(), best.entity.name()))    
      self.log("    Score: 1.0, perfect match, updating tags")
      best.match.merge(entity)
      entity.data = best.match.data
    elif best.score > threshold:
      self.log(" -> %s: %s"%(best.match.onestop(), best.entity.name()))    
      self.log("    Score: %0.2f above threshold %0.2f, merging"%(best.score, threshold))
      best.match.merge(entity)
      entity.data = best.match.data
    else:
      self.log(" -> No match above threshold %0.2f"%threshold)
    return entity

  def update_feed(self, feed):
    entities = set()
    entities |= feed.operators()
    entities |= feed.routes()
    entities |= feed.stops()
    self.datastore.update_entities(entities)
     
if __name__ == "__main__":
  FeedEaterPost.run_from_args()
