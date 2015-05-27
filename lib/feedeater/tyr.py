"""TYR interface."""
import json
import urllib
import urllib2
import collections

import util

def tyr_osm(stop, endpoint, apitoken=None, debug=False):
  t = TYR(tyrhost, apitoken=apitoken, debug=debug)
  response = t.locate([stop.point()])
  try:
    assert response
    assert response[0]['ways']
  except:
    return None
  ways = collections.defaultdict(list)
  for way in response[0]['ways']:
    d = util.haversine(stop.point(), (way['correlated_lon'], way['correlated_lat']))
    ways[d].append(way['way_id'])
  # get the lowest way_id in the closest way.
  way_id = sorted(ways[sorted(ways.keys())[0]])[0]
  return way_id
  
class TYR(object):
  def __init__(self, endpoint, apitoken=None, debug=False):
    self.endpoint = endpoint
    self.apitoken = apitoken
    
  def locate(self, locations, costing='pedestrian'):
    data = {
      'locations': [
        {'lon':i[0], 'lat':i[1]} for i in locations
      ],
      'costing': costing  
    }
    return self.getjson('%s/locate'%self.endpoint, json=json.dumps(data))

  def getjson(self, endpoint, **qs):
    if self.apitoken:
      qs['api_key'] = self.apitoken
    if qs:
      endpoint = '%s?%s'%(
        endpoint,
        urllib.urlencode(qs)
      )
    req = urllib2.Request(endpoint)
    response = urllib2.urlopen(req)
    ret = response.read()
    try:
      ret = json.loads(ret)
    except ValueError, e:
      return None
    return ret
