describe FeedEaterWorker do
  it 'should pull the latest Onestop ID Registry' do
    allow(OnestopIdClient::Registry).to receive(:repo) { true }
    worker = FeedEaterWorker.new
    worker.perform
    expect(OnestopIdClient::Registry).to have_received(:repo)
  end
end
