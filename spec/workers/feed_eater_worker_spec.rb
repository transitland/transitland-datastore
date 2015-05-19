describe FeedEaterWorker do
  it 'should pull the latest Transitland Feed Registry' do
    allow(TransitlandClient::FeedRegistry).to receive(:repo) { true }
    worker = FeedEaterWorker.new
    worker.perform
    expect(TransitlandClient::FeedRegistry).to have_received(:repo)
  end
end
