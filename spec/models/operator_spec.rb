# == Schema Information
#
# Table name: current_operators
#
#  id                                 :integer          not null, primary key
#  name                               :string
#  tags                               :hstore
#  created_at                         :datetime
#  updated_at                         :datetime
#  onestop_id                         :string
#  geometry                           :geography({:srid geometry, 4326
#  created_or_updated_in_changeset_id :integer
#  version                            :integer
#  identifiers                        :string           default([]), is an Array
#  timezone                           :string
#  short_name                         :string
#  website                            :string
#  country                            :string
#  state                              :string
#  metro                              :string
#
# Indexes
#
#  #c_operators_cu_in_changeset_id_index   (created_or_updated_in_changeset_id)
#  index_current_operators_on_identifiers  (identifiers)
#  index_current_operators_on_onestop_id   (onestop_id) UNIQUE
#  index_current_operators_on_tags         (tags)
#  index_current_operators_on_updated_at   (updated_at)
#

describe Operator do
  it 'can be created' do
    operator = create(:operator)
    expect(Operator.exists?(operator.id)).to be true
  end

  it 'can be found by identifier and/or name' do
    bart = create(:operator, name: 'BART', identifiers: ['Bay Area Rapid Transit'])
    sfmta = create(:operator, name: 'SFMTA')
    expect(Operator.with_identifier('Bay Area Rapid Transit')).to match_array([bart])
    expect(Operator.with_identifier_or_name('BART')).to match_array([bart])
    expect(Operator.with_identifier('SFMTA')).to be_empty
    expect(Operator.with_identifier_or_name('SFMTA')).to match_array([sfmta])
  end

  it 'IsAnEntityImportedFromFeeds imported_from_feed_onestop_id' do
    feed = create(:feed)
    bart = build(:operator, name: 'BART', identifiers: ['Bay Area Rapid Transit'])
    bart.imported_from_feed_onestop_id = feed.onestop_id
    bart.save!
    expect(bart.imported_from_feeds).to match_array([feed])
  end

  it 'IsAnEntityImportedFromFeeds imported_from_feed_onestop_id requires valid feed onestop_id' do
    bart = build(:operator, name: 'BART', identifiers: ['Bay Area Rapid Transit'])
    expect {
      bart.imported_from_feed_onestop_id = 'f-9q9-unknown'
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'IsAnEntityImportedFromFeeds imported_from_feed_onestop_id no duplicates' do
    feed = create(:feed)
    bart = build(:operator, name: 'BART', identifiers: ['Bay Area Rapid Transit'])
    bart.imported_from_feed_onestop_id = feed.onestop_id
    bart.save!
    expect(bart.imported_from_feeds).to match_array([feed])
    bart.imported_from_feed_onestop_id = feed.onestop_id
    bart.save!
    expect(bart.imported_from_feeds).to match_array([feed])
  end

end
