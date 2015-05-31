describe HasTags do
  before(:each) do
    @yes = create(:stop, tags: { wheelchair_accessible: 'yes' })
    @no = create(:stop, tags: { wheelchair_accessible: 'no' })
    @none = create(:stop)
  end

  it 'with_tag' do
    expect(Stop.with_tag(:wheelchair_accessible)).to match_array([@yes, @no])
  end

  it 'with_tag_equals' do
    expect(Stop.with_tag_equals(:wheelchair_accessible, 'yes')).to match_array([@yes])
  end
end
