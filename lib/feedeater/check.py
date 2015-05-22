"""Check Transitland Feed Registry GTFS feeds for updates."""
import os

import util
import task

class FeedEaterCheck(task.FeedEaterTask):
  @classmethod
  def parser(cls):
    return task.default_parser(cls.__doc__, feedids=True)

  def run(self):
    # Check feeds
    newfeeds = []
    feedids = self.feedids or self.registry.feeds()
    for feedid in feedids:
      feed = self.registry.feed(feedid)
      filename = os.path.join(self.workdir, '%s.zip'%feed.onestop())
      if feed.verify_sha1(filename):
        pass
      else:
        newfeeds.append(feedid)
    return newfeeds

if __name__ == "__main__":
  task = FeedEaterCheck.from_args()  
  newfeeds = task.run()
  print " ".join(newfeeds)