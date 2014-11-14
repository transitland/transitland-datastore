describe AbbreviateStopName do
  it 'handles "&" and "and"' do
    expect(AbbreviateStopName.new('4th & King').abbreviate(6)).to eq '4thKin'
    expect(AbbreviateStopName.new('4th and King').abbreviate(6)).to eq '4thKin'
  end

  it 'handles 2 and 3 word names' do
    expect(AbbreviateStopName.new('Embarcadero Metro').abbreviate(6)).to eq 'EmbMet'
    expect(AbbreviateStopName.new('North Main Street').abbreviate(6)).to eq 'NoMaSt'
  end

  it 'handles dashes and slashes' do
    expect(AbbreviateStopName.new('Grand Central Station - Concourse').abbreviate(6)).to eq 'GCeSCo'
    expect(AbbreviateStopName.new('San Francisco International Airport/Terminal 1').abbreviate(6)).to eq 'SFIAT1'
  end
end
