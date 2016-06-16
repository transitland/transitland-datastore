describe QualityCheck do
  it 'finds existing duplicate issues' do

  end
end

describe GeometryQualityCheck do

  before(:each) do
    @feed, @feed_version = load_feed(feed_version_name: :feed_version_example_issues, import_level: 1)
    @quality_check = GeometryQualityCheck.new(changeset: @feed_version.changesets_imported_from_this_feed_version.first)
  end

  it 'creates new issues in check' do
    expect(@quality_check.check.size).to eq 1
  end
end
