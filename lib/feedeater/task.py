"""Base FeedEater Task."""
import sys
import os
import argparse
import logging

import transitland.registry
import transitland.datastore
import logging

def default_parser(description=None, feedids=False):
  parser = argparse.ArgumentParser(description=description)
  if feedids:
    parser.add_argument(
      'feedids',
      nargs='*',
      help='Feed IDs'
    )
  else:
    parser.add_argument(
      'feedid', 
      help='Feed ID'
    )
  parser.add_argument(
    '--registry', 
    help='Feed registry path',
    default=os.getenv('TRANSITLAND_FEED_REGISTRY_PATH')
  )
  parser.add_argument(
    '--workdir',
    help='Feed data directory',
    default=os.getenv('TRANSITLAND_FEED_DATA_PATH')
  )
  parser.add_argument(
    "--host",
    help="Datastore host",
    default=os.getenv('TRANSITLAND_DATASTORE_HOST') or 'http://localhost:3000'
  )
  parser.add_argument(
    '--apitoken',
    help='Datastore api token',
    default=os.getenv('TRANSITLAND_DATASTORE_AUTH_TOKEN')
  )
  parser.add_argument(
    '--debug', 
    help='Debug', 
    action='store_true'
  )
  parser.add_argument(
    '--filename',
    help='Specify GTFS filename manually'
  )  
  parser.add_argument(
    '--log',
    help='Log file'
  )  
  return parser

class FeedEaterTask(object):  
  def __init__(
      self,
      filename=None,
      feedid=None, 
      feedids=None,
      registry=None,
      workdir=None,
      host=None,
      apitoken=None,
      debug=None,
      log=None,
      **kwargs
    ):
    self.filename = filename
    self.feedid = feedid
    self.feedids = feedids
    self.registry = transitland.registry.FeedRegistry(path=registry)
    self.workdir = workdir or os.path.join(self.registry.path, 'data')
    self.datastore = transitland.datastore.Datastore(
      host,
      apitoken=apitoken,
      debug=debug
    )
    self.logger = self._log_init(logfile=log, debug=debug)
    
  def _log_init(self, logfile=None, debug=False):
    fmt = '[%(asctime)s] %(message)s'
    datefmt = '%Y-%m-%d %H:%M:%S'
    logger = logging.getLogger(str(id(self)))
    if debug:
      logger.setLevel(logging.DEBUG)
    else:
      logger.setLevel(logging.INFO)
    if logfile:
      logfile = os.path.join(self.workdir, logfile)
      fh = logging.FileHandler(logfile)
    else:
      fh = logging.StreamHandler(sys.stdout) 
    fh.setLevel(logging.DEBUG)
    formatter = logging.Formatter(fmt, datefmt=datefmt)
    fh.setFormatter(formatter)
    logger.addHandler(fh)
    return logger
    
  @classmethod
  def from_args(cls):
    parser = cls().parser()
    args = parser.parse_args()  
    return cls(**vars(args))

  def parser(self):
    return default_parser(self.__doc__)
    
  def debug(self, msg):
    self.logger.debug(msg)
    
  def log(self, msg):
    # '[%s] %s'%(self.feedid, msg)
    self.logger.info(msg)
  
  def run(self):
    pass
    
if __name__ == "__main__":
  task = FeedEaterTask.from_args()
