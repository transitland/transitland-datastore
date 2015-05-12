"""Validate GTFS"""
import os
import subprocess
import argparse

import mzgtfs.feed
import transitland.registry

import util

class FeedEaterValidator(object):
  def __init__(self, filename):
    self.exceptions = []
    self.filename = filename
    
  def errors(self):
    # Filter for errors
    return self.exceptions
    
  def warnings(self):
    # Filter for warnings
    return self.exceptions    
    
  def validate(self):
    feed = mzgtfs.feed.Feed(self.filename)
    print "Date ranges:", feed.dates()  
    print "Internal validation..."
    result = feed.validate()
    print "...:", result
    
  def feedvalidator(self, report='report.html'):
    self.exceptions = []
    p = subprocess.Popen(
      [
        'feedvalidator.py',
        '--memory_db',
        '--noprompt',
        '--output',
        report,
        self.filename
      ],
      stdout=subprocess.PIPE, 
      stderr=subprocess.PIPE
    )
    stdout, stderr = p.communicate()
    returncode = p.returncode
    errors = [i for i in stdout.split('\n') if i.startswith('ERROR:')]
    if returncode:
      self.exceptions.append(Exception('Invalid feed'))

def run():
  parser = util.default_parser('Validate GTFS')
  args = parser.parse_args()
  #
  r = transitland.registry.FeedRegistry(path=args.registry)
  feedids = args.feedids
  if args.all:
    feedids = r.feeds()
  if len(feedids) == 0:
    raise Exception("No feeds specified! Try --all")
  #
  for feedid in feedids:
    feed = r.feed(feedid)
    filename = os.path.join(args.workdir, '%s.zip'%feed.onestop())
    reportfilename = os.path.join(args.workdir, '%s.html'%feed.onestop())
    # 
    validator = FeedEaterValidator(filename)
    validator.validate()
    validator.feedvalidator(report=reportfilename)
    if validator.errors():
      print "Feed contains errors."
    elif validator.warnings():
      print "Feed contains warnings."
    else:
      print "Feed appears valid!"
      
    
if __name__ == "__main__":
  run()