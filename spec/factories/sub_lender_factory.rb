FactoryGirl.define do
  factory :sub_lender do
    sequence(:name) { |n| "Sub-lender #{n}" }
  end
end
