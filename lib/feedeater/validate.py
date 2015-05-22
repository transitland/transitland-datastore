"""Validate GTFS"""
import os

import mzgtfs.feed
import mzgtfs.validation

import task

class FeedEaterValidate(task.FeedEaterTask):
  def run(self):
    # Validate feeds
    print "===== Feed: %s ====="%self.feedid
    feed = self.registry.feed(self.feedid)
    filename = self.filename or os.path.join(self.workdir, '%s.zip'%feed.onestop())
    report = os.path.join(self.workdir, '%s.html'%feed.onestop())
    print "Validating: %s"%filename
    gtfsfeed = mzgtfs.feed.Feed(filename, debug=self.debug)    
    validator = mzgtfs.validation.ValidationReport()
    # gtfsfeed.validate(validator)
    gtfsfeed.validate_feedvalidator(validator, report=report)
    validator.report()
    
if __name__ == "__main__":
  task = FeedEaterValidate.from_args()
  task.run()
