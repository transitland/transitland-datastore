"""Datastore Updater."""
import os
import time
import json
import datetime

import mzgtfs.feed

import similarity
import task
import util

# ISO Weekdays
DOW = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']

def id_map(entities, key):
  """Map GTFS Entity IDs to Onestop IDs."""
  ret = {}
  for entity in entities:
    t = getattr(entity, '_tl_ref', None)
    if t:
      ret[entity.get(key)] = t.onestop()
  return ret

def to_date(v):
  """GTFS date string to ISO date string."""
  return datetime.datetime.strptime(v, '%Y%m%d').date().isoformat()

def to_bool(v):
  """GTFS 0/1/empty to true/false"""
  if v:
    return bool(int(v))
  return False

def to_int(v):
  """GTFS string to int"""
  try:
    return int(v)
  except (ValueError, TypeError), e:
    return None

def to_float(v):
  """GTFS string to float"""
  try:
    return float(v)
  except (ValueError, TypeError), e:
    return None

def make_service(cal=None):
  """TL ScheduleStopPair from GTFS calendar."""
  cal = cal or {}
  return {
    'serviceStartDate': to_date(cal.get('start_date')),
    'serviceEndDate': to_date(cal.get('end_date')),
    'serviceDaysOfWeek': [to_bool(cal.get(i)) for i in DOW],
    'serviceAdded': [],
    'serviceExcept': []
  }

def make_calendar(gtfs_feed):
  """Create TL ScheduleStopPairs from GTFS calendar & calendar_dates."""
  ret = {}
  for i in gtfs_feed.read('calendar'):
    sid = i.get('service_id')
    ret[sid] = make_service(i)
  for i in gtfs_feed.read('calendar_dates'):
    sid = i.get('service_id')
    if sid not in ret:
      ret[sid] = make_service()
    if i.get('exception_type') == '1':
      ret[sid]['serviceAdded'].append(to_date(i.get('date')))
    else:
      ret[sid]['serviceExcept'].append(to_date(i.get('date')))
  return ret

def make_ssp(gtfs_feed):
  """Generator for TL ScheduleStopPairs from GTFS feed."""
  # Load calendar data
  cals = make_calendar(gtfs_feed)
  # Map gtfs ids to onestop ids
  # agency_id_map = id_map(gtfs_feed.agencies(), 'agency_id')
  # route_id_map = id_map(gtfs_feed.routes(), 'route_id')
  # stop_id_map = id_map(gtfs_feed.stops(), 'stop_id')
  # Load step edges
  for origin_stop in gtfs_feed.stops():
    for origin_stoptime in origin_stop.parents():
      for trip in origin_stoptime.parents():
        seq = trip.stop_sequence()
        pos = seq.index(origin_stoptime)
        if pos+1 >= len(seq):
          continue
        destination_stoptime = seq[pos+1]
        destination_stop = list(destination_stoptime.children())[0]
        route = list(trip.parents())[0]          
        # Reference to TL Entity
        origin_tl = origin_stop._tl_ref
        destination_tl = destination_stop._tl_ref
        # 
        # Calendar
        cal = cals[trip.get('service_id')]
        ssp = {
          # origin
          'originOnestopId': origin_tl.onestop(),
          'originTimezone': origin_tl.get_timezone(),
          'originArrivalTime': str(origin_stoptime.arrive()),
          'originDepartureTime': str(origin_stoptime.depart()),
          # destination
          'destinationOnestopId': destination_tl.onestop(),
          'destinationTimezone': destination_tl.get_timezone(),
          'destinationArrivalTime': str(destination_stoptime.arrive()),
          'destinationDepartureTime': str(destination_stoptime.depart()),
          # route
          'routeOnestopId': route._tl_ref.onestop(),
          # trip
          'trip': trip.id(),
          'tripHeadsign': origin_stoptime.get('stop_headsign') or trip.get('trip_headsign'),
          'tripShortName': trip.get('trip_short_name'),
          'wheelchairAccessible': to_int(trip.get('wheelchair_accessible')),
          'bikesAllowed': to_int(trip.get('bikes_allowed')),
          # stoptime
          'dropOffType': to_int(origin_stoptime.get('drop_off_type')),
          'pickupType': to_int(origin_stoptime.get('pickup_type')),
          'timepoint': to_int(origin_stoptime.get('timepoint')),
          'shapeDistTraveled': to_float(origin_stoptime.get('shape_dist_traveled')),
        }
        ssp.update(cal)
        yield ssp
     
def change_entity(entity, action='createUpdate'):
  """Return an entity formatted as a Change."""
  # Wrap entity in change
  onestop_types = {
    's': 'stop',
    'r': 'route',
    'o': 'operator',
    't': 'scheduleStopPair'
  }
  keys = [
    'onestopId',
    'name',
    'geometry',
    'tags',
    'identifiers',
    'operatedBy',
    'servedBy',
    'timezone',
  ]
  # 
  data = entity.json()
  change = {}
  for key in keys:
    if key in data:
      change[key] = data.get(key)
  if 'identifiers' in keys:
      change['identifiedBy'] = change.pop('identifiers')
  return {
    'action': action,
    onestop_types[entity.onestop_type]: change
  }

def change_ssp(entity, action='createUpdate'):
  """Return an SSP formatted as a Change."""
  # Wrap SSP in change
  return {
    'action': action,
    'scheduleStopPair': entity
  }

class FeedEaterPost(task.FeedEaterTask):
  """FeedEater Task to upload a GTFS feed as a Changeset."""
  BATCHSIZE = 1000

  def __init__(self, *args, **kwargs):
    super(FeedEaterPost, self).__init__(*args, **kwargs)
    self.schedule_stop_pairs = kwargs.get('schedule_stop_pairs')

  @classmethod
  def parser(cls):
    parser = super(FeedEaterPost, cls).parser()
    parser.add_argument(
      '--schedule_stop_pairs',
      action='store_true'
    )
    return parser

  def run(self):
    # Update datastore.
    self.log("===== Feed: %s ====="%self.feedid)
    feed = self.registry.feed(self.feedid)
    filename = self.filename or os.path.join(self.workdir, '%s.zip'%feed.onestop())
    self.log("Opening: %s"%filename)
    gtfs_feed = mzgtfs.feed.Feed(filename)
    self.log("Creating Onestop Entities")
    gtfs_feed.preload()
    feed.load_gtfs(gtfs_feed, populate=False)
    if not feed.operators():
      self.log("No matching operators specified in the feed registry entry. Nothing to do.")
      return

    # Precalculate all Onestop IDs
    for o in feed.operators():
      o._cache_onestop()

    # Compare against datastore entities and merge if possible.
    for stop in feed.stops():
      self._merge_stop(stop)
      
    # Upload changeset.
    self.log("Updating feed: %s"%feed.onestop())

    # Create empty changeset
    changeset = self.datastore.postjson('/api/v1/changesets', {"changeset": {"payload": {}}} )
    changeset_id = changeset['id']
    self.log("Changeset ID: %s"%changeset_id)
    
    # Append each entity
    self._append_batch(feed.operators(), changeset_id, change_entity)  
    self._append_batch(feed.routes(), changeset_id, change_entity)  
    self._append_batch(feed.stops(), changeset_id, change_entity)  
    if self.schedule_stop_pairs:
      self._append_batch(make_ssp(gtfs_feed), changeset_id, change_ssp)

    # Apply changeset
    self.log("Applying changeset...")
    self.datastore.postjson('/api/v1/changesets/%s/apply'%changeset_id)
    self.log("  -> ok")
    self.log("Finished!")

  def _merge_stop(self, entity, threshold=0.5):
    """Search for an existing TLDS Stop."""
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

  def _append_batch(self, entities, changeset_id, changefunc, batchsize=1000, word='entities'):
    """Append entities to a Changeset as a batch."""
    batch = []
    for entity in entities:
      batch.append(changefunc(entity))
      if len(batch) == batchsize:
        self.log("  batch of %s %s"%(len(batch), word))
        self.datastore.postjson('/api/v1/changesets/%s/append'%changeset_id, {'changes':batch})
        batch = []
    if batch:
      self.log("  batch of %s %s"%(len(batch), word))
      self.datastore.postjson('/api/v1/changesets/%s/append'%changeset_id, {'changes':batch})

if __name__ == "__main__":
  FeedEaterPost.run_from_args()
