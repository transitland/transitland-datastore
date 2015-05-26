"""Validate GTFS"""
import os

import mzgtfs.feed
import mzgtfs.validation

import task

class FeedEaterValidate(task.FeedEaterTask):
  def __init__(self, *args, **kwargs):
    super(FeedEaterValidate, self).__init__(*args, **kwargs)
    self.feedvalidator = kwargs.get('feedvalidator')

  def parser(self):
    parser = super(FeedEaterValidate, self).parser()
    parser.add_argument(
      '--feedvalidator',
      help='Path to feedvalidator.py'
    )  
    return parser
    
  def run(self):
    # Validate feeds
    self.log("===== Feed: %s ====="%self.feedid)
    feed = self.registry.feed(self.feedid)
    filename = self.filename or os.path.join(self.workdir, '%s.zip'%feed.onestop())
    report = os.path.join(self.workdir, '%s.html'%feed.onestop())
    self.log("Validating: %s"%filename)
    gtfsfeed = mzgtfs.feed.Feed(filename)    
    validator = mzgtfs.validation.ValidationReport()
    # gtfsfeed.validate(validator)
    gtfsfeed.validate_feedvalidator(
      validator, 
      feedvalidator=self.feedvalidator,
      report=report,
    )
    # validator.report()
    self.log("Validation report:")
    if not validator.exceptions:
      self.log("No errors")
    for e in validator.exceptions:
      self.log("%s: %s"%(e.source, e.message))
    
if __name__ == "__main__":
  task = FeedEaterValidate.from_args()
  task.run()
