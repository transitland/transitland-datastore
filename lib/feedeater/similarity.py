"""Similarity utilities."""
import math
import difflib
import collections

import mzgeohash
import util

def seqratio(a, b):
  """Sequence similarity between strings."""
  # Use Python standard library SequenceMatcher,
  # which is based on the Ratcliff-Obershelp algorithm, improved to
  # ignore "junk" elements.
  return difflib.SequenceMatcher(None, a, b).ratio()

def score_distance(e1, e2):
  """Score on the inverse distance."""
  d = util.haversine(e1.point(), e2.point())
  return 1/(d+1.0)

def score_name(e1, e2):
  """Score on name similarity."""
  return seqratio(e1.name(), e2.name())

def score_name_distance(e1, e2):
  """Score on name and inverse distance, equally weighted."""
  return score_distance(e1, e2) * 0.5 + score_name(e1, e2) * 0.5

def filter_threshold(matches, threshold=0.5):
  return filter(lambda x:x.score >= threshold, matches)

class Match(object):
  """Result of a comparison between two entities."""
  def __init__(self, entity, match=None, score=0.0):
    self.entity = entity
    self.match = match
    self.score = score
    
  def __str__(self):
    if self.match:
      return "Match: %s <-> %s (score: %0.2f, d: %0.2fm)"%(
        self.entity.name(), 
        self.match.name(), 
        self.score,
        util.haversine(self.entity.point(), self.match.point())
      )
    else:
      return "Match: %s <-> no result"%(
        self.entity.name()
      )

class MatchEntities(object):
  def __init__(self, entity, search_entities, score_func=None):
    """Compare entities."""
    self.entity = entity
    self.search_entities = search_entities
    self.score_func = score_func or score_name_distance    
    self.result = []
  
  def score(self):
    """Return the best matching entity."""  
    results = []
    for search_entity in self.search_entities:
      result = Match(
        self.entity, 
        search_entity, 
        self.score_func(self.entity, search_entity)
      )
      results.append(result)
    self.results = results
  
  def best(self):
    results = sorted(self.results, key=lambda x:x.score, reverse=True)
    if results:
      best = results[0]
    else:
      best = Match(self.entity)
    return best
