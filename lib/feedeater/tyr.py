"""TYR interface."""
import json
import urllib
import urllib2
import collections

class TYR(object):
  def __init__(self, endpoint, apitoken=None, debug=False):
    self.endpoint = endpoint
    self.apitoken = apitoken
    self.debug = debug    
    
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
    if self.debug:
      print "====== GET: %s ======"%endpoint
    req = urllib2.Request(endpoint)
    response = urllib2.urlopen(req)
    ret = response.read()
    try:
      ret = json.loads(ret)
    except ValueError, e:
      return None
    if self.debug:
      print "--> Response: "
      print ret
    return ret
