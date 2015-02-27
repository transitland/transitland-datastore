FactoryGirl.define do
  factory :route do
    onestop_id { Faker::OnestopId.route }
    name { [
      '19 Polk',
      'N Judah',
      '522 Rapid'
    ].sample }
    version 1
    association :created_or_updated_in_changeset, factory: :changeset
  end
end
