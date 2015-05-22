"""FeedEater utilities."""
import os
import argparse
import math

def makedirs(path):
  if not path:
    raise OSError("No path specified")
  try:
    os.makedirs(path)
  except OSError, e:
    pass

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
