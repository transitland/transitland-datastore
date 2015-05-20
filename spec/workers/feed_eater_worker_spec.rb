describe FeedEaterWorker do
  it 'should pull the latest Transitland Feed Registry' do
    allow(TransitlandClient::FeedRegistry).to receive(:repo) { true }
    worker = FeedEaterWorker.new
    allow(worker).to receive(:system) { true } # skip system calls to Python code
    worker.perform
    expect(TransitlandClient::FeedRegistry).to have_received(:repo)
  end
end
