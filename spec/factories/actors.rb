FactoryBot.define do
  factory :actor do
    sequence(:github_id) { |n| 1000 + n }
    sequence(:login) { |n| "user#{n}" }
    avatar_url { "https://avatars.githubusercontent.com/u/#{github_id}" }
    raw_payload { { id: github_id, login: login, type: "User" } }
  end
end
