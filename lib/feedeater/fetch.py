"""Fetch Transitland Feed Registry feeds."""
import os

import util
import task

class FeedEaterFetch(task.FeedEaterTask):
  def run(self):
    # Download feeds
    self.log("===== Feed: %s ====="%self.feedid)
    feed = self.registry.feed(self.feedid)
    filename = self.filename or os.path.join(self.workdir, '%s.zip'%feed.onestop())
    if feed.verify_sha1(filename):
      self.log("Cached")
    else:
      self.log("Downloading: %s -> %s"%(feed.url(), filename))
      util.makedirs(self.workdir)
      feed.download(filename, verify=False)
    if not feed.verify_sha1(filename):
      self.log("Warning: Incorrect SHA1 checksum.")
    
if __name__ == "__main__":
  task = FeedEaterFetch.from_args()
  task.run()