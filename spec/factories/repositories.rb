FactoryBot.define do
  factory :repository do
    sequence(:github_id) { |n| 2000 + n }
    sequence(:name) { |n| "repo#{n}" }
    sequence(:full_name) { |n| "owner/repo#{n}" }
    raw_payload { { id: github_id, name: name, full_name: full_name } }
  end
end
