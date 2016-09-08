describe FeedEaterWorker do
  before(:each) do
    @feedids = ['f-9q9-caltrain']
    @feeds = @feedids.map {|feedid| Feed.new(onestop_id:feedid)}
  end

  # TODO: Additional testing
  #   failure cases
  #   log file upload

end
