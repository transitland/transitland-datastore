"""Validate GTFS"""
import os
import subprocess
import argparse

import mzgtfs.feed
import mzgtfs.validation
import transitland.registry

import util

def run():
  parser = util.default_parser('Validate GTFS')
  args = parser.parse_args()

  # Registry
  r = transitland.registry.FeedRegistry(path=args.registry)

  # Validate feeds
  feedids = args.feedids or r.feeds()
  for feedid in feedids:
    print "===== Feed: %s ====="%feedid
    feed = r.feed(feedid)
    filename = os.path.join(args.workdir, '%s.zip'%feed.onestop())
    report = os.path.join(args.workdir, '%s.html'%feed.onestop())
    print "Validating: %s"%filename
    gtfsfeed = mzgtfs.feed.Feed(filename, debug=args.debug)    
    validator = mzgtfs.validation.ValidationReport()
    # gtfsfeed.validate(validator)
    gtfsfeed.validate_feedvalidator(validator, report=report)
    validator.report()
    
if __name__ == "__main__":
  run()