"""FeedEater utilities."""
import os
import argparse

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
  return parser