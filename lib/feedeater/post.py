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
    infeed = self.registry.feed(self.feedid)
    filename = self.filename or os.path.join(self.workdir, '%s.zip'%infeed.onestop())
    self.log("Opening: %s"%filename)
    gtfsfeed = mzgtfs.feed.Feed(filename)
    self.log("Creating Onestop Entities")
    feed = transitland.entities.Feed.from_gtfs(gtfsfeed, feedid=self.feedid)

    # Similarity search.
    for o in feed.operators():
      o._cache_onestop()

    # Compare against datastore entities and merge if possible.
    for stop in feed.stops():
      self.datastore_merge(stop)
      
    # Post changesets.
    for operator in feed.operators():
      self.update_operator(operator)
  
  def datastore_merge(self, entity, threshold=0.5):
    self.log("Looking for entity: %s"%entity.onestop())
    search_entities = self.datastore.stops(point=entity.point(), radius=1000)   
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
  
  def update_operator(self, operator):
    self.log("Updating operator: %s"%operator.onestop())
    entities = sorted(
      operator.stops() | operator.routes(), 
      key=lambda x:x.onestop()
    )
    # Post without relationships
    self.datastore.update_entity(operator, rels=False)
    for entity in entities:
      self.log("  ... %s"%entity.onestop())
      self.datastore.update_entity(entity, rels=False)
    # Update relationships
    self.datastore.update_entity(operator)
    for entity in entities:
      self.log("  ... %s (rels)"%entity.onestop())
      self.datastore.update_entity(entity)
     
  # def update_operator(self, operator):
  #   self.log("Updating operator: %s"%operator.onestop())
  #   entities = []
  #   entities.append(operator)
  #   entities += list(operator.stops())
  #   entities += list(operator.routes())
  #   self.datastore.update_entities(entities)
     
if __name__ == "__main__":
  task = FeedEaterPost.from_args()
  task.run()
