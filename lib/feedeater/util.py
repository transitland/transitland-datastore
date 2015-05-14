"""FeedEater utilities."""
import os
import argparse
import math

def default_parser(description=None):
  parser = argparse.ArgumentParser(description=description)
  parser.add_argument(
    'feedids', 
    help='Feed IDs',
    nargs='*'
  )
  parser.add_argument(
    '--registry', 
    help='Feed Registry Path',
    default=os.getenv('TRANSITLAND_FEED_REGISTRY_PATH')
  )
  parser.add_argument(
    '--workdir',
    help='Work/data directory',
    default=os.path.join(os.getenv('TRANSITLAND_FEED_REGISTRY_PATH'), 'data')
  )
  parser.add_argument(
    '--all', 
    help='Update all feeds', 
    action='store_true'
  )
  parser.add_argument(
    '--verbose', 
    help='Verbosity', 
    type=int, 
    default=1
  )
  parser.add_argument(
    '--debug', 
    help='Debug', 
    action='store_true'
  )
  return parser
  
def haversine(point1, point2):
  """Haversine distance between two (lon,lat) points, in km."""
  # Based on description of Haversine formula:
  # http://www.movable-type.co.uk/scripts/latlong.html
  radius = 6371000 # m
  # Decimal to radians
  lon1, lat1 = map(math.radians, point1)
  lon2, lat2 = map(math.radians, point2)
  # Haversine
  dlon = lon2 - lon1
  dlat = lat2 - lat1
  a =  \
    math.sin(dlat/2)**2 + \
    math.cos(lat1) * \
    math.cos(lat2) * \
    math.sin(dlon/2)**2
  c = 2 * math.atan2(a**0.5, (1-a)**0.5)
  return c * radius
