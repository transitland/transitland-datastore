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
    before(:each) do
      Stop.stub(:match_against_existing_stop_or_create) { true }
    end

    it 'will try to match or create a record for each stop' do
      expect(Stop).to receive(:match_against_existing_stop_or_create).exactly(3859).times
      @vta_gtfs_import.import
    end

    it 'will run an optional block after each stop is imported' do
      @i = 0
      @sfmta_gtfs_import.import { @i += 1 }
      expect(@i).to eq 3599
    end
  end
end
