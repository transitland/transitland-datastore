FactoryGirl.define do
  factory :stop_platform, class: StopPlatform, parent: :stop do
    association :parent_stop, factory: :stop
  end
end
