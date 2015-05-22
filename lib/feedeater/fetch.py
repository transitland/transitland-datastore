"""Fetch Transitland Feed Registry feeds."""
import os

import util
import task

class FeedEaterFetch(task.FeedEaterTask):
  def run(self):
    # Download feeds
    print "===== Feed: %s ====="%self.feedid
    feed = self.registry.feed(self.feedid)
    filename = self.filename or os.path.join(self.workdir, '%s.zip'%feed.onestop())
    if feed.verify_sha1(filename):
      print "Cached"
    else:
      print "Downloading: %s -> %s"%(feed.url(), filename)
      util.makedirs(self.workdir)
      feed.download(filename, verify=False)
    if not feed.verify_sha1(filename):
      print "Warning: Incorrect SHA1 checksum."
    
if __name__ == "__main__":
  task = FeedEaterFetch.from_args()
  task.run()