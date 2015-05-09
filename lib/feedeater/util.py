"""FeedEater utilities."""
import argparse

def default_parser(description=None):
  parser = argparse.ArgumentParser(description=description)
  parser.add_argument('feedids', nargs='*', help='Feed IDs')
  parser.add_argument('--registry', help='Feed Registry Path')
  parser.add_argument('--all', help='Update all feeds', action='store_true')
  parser.add_argument('--verbose', help='Verbosity', type=int, default=1)
  return parser