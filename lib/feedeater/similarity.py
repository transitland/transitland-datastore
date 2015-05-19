"""Comparison utilities."""
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

class ScoreResult(object):
  """Result of a comparison between two entities."""
  def __init__(self, source, match=None, score=0.0):
    self.source = source
    self.match = match
    self.score = score
    
  def print_match(self, indent=''):
    if self.match:
      print "%s%s <-> %s (score: %0.2f, d: %0.2fm, ds: %0.2f, ss: %0.2f)"%(
        indent,
        self.source.name(), 
        self.match.name(), 
        self.score,
        util.haversine(self.source.point(), self.match.point()),
        score_distance(self.source, self.match),
        score_name(self.source, self.match)
      )
    else:
      print "%s%s <-> no result"%(
        indent, 
        self.source.name()
      )

class CompareEntities(object):
  def __init__(self, entity, search_entities, score_func=None):
    """Compare entities."""
    self.entity = entity
    self.search_entities = search_entities
    self.score_func = score_func or score_name_distance    
    self.result = []
  
  def find_search_entities(self):
    """Find a set of entities to compare against."""
    return self.search_entities

  def score(self):
    """Return the best matching entity."""  
    results = []
    for search_entity in self.find_search_entities():
      result = ScoreResult(
        self.entity, 
        search_entity, 
        self.score_func(self.entity, search_entity)
      )
      results.append(result)
    self.results = results
  
  def merge(self, threshold=0.5, indent=''):
    """Merge the entity with the best result."""
    results = sorted(self.results, key=lambda x:x.score, reverse=True)
    if results:
      best = results[0]
    else:
      best = ScoreResult(self.entity)
    best.print_match(indent=indent)
    
    # Identifier matches.
    idm = set()
    if best.match:
      idm = set(self.entity.identifiers()) & set(best.match.identifiers())

    # Score results.
    if best.score == 1.0:
      print "\tperfect match, updating tags..."
      best.match.merge(self.entity)
      self.entity.data = best.match.data
    # elif best.score > threshold and idm:
    #   print "\tid match"
    #   return self.entity
    elif best.score > threshold:
      print "%sscore above threshold, merging..."%indent
      best.match.merge(self.entity)
      self.entity.data = best.match.data
    else:
      print "%s...no match."%indent
      
    return self.entity

