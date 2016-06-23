FactoryGirl.define do
  factory :stop_egress, class: StopEgress, parent: :stop do
    association :parent_stop, factory: :stop
  end
end
