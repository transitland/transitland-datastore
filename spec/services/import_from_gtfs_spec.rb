describe ImportFromGtfs do
  before(:all) do
    @vta_gtfs_import = ImportFromGtfs.new(__dir__ + '/../support/example_gtfs_archives/vta_gtfs.zip')
    @sfmta_gtfs_import = ImportFromGtfs.new(__dir__ + '/../support/example_gtfs_archives/sfmta_gtfs.zip')
  end

  context 'GTFS archive' do
    it 'can be opened' do
      expect(@vta_gtfs_import.gtfs).to be_instance_of GTFS::LocalSource
    end

    it 'can have its stops parsed' do
      expect(@sfmta_gtfs_import.gtfs.stops.count).to eq 3599
      expect(@sfmta_gtfs_import.gtfs.stops.first.name).to eq '19th Avenue & Holloway St'
    end
  end

  context 'import' do
    # TODO: rewrite these tests with mocks/stubs so they're quicker

    it "will create records (Stop and StopIdentifier's) for each stop" do
      @vta_gtfs_import.import
      expect(Stop.count).to eq 3859
      expect(StopIdentifier.count).to eq 7718
      expect(StopIdentifier.first.tags['gtfs_source']).to eq 'vta_gtfs.zip'
    end

    it 'will run an optional block after each stop is imported' do
      @i = 0
      @sfmta_gtfs_import.import { @i += 1 }
      expect(@i).to eq 3599
    end
  end
end
