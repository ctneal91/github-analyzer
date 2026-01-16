FactoryBot.define do
  factory :rate_limit_state do
    endpoint { "https://api.github.com/events" }
    remaining { 60 }
    resets_at { 1.hour.from_now }

    trait :exhausted do
      remaining { 0 }
      resets_at { 30.minutes.from_now }
    end

    trait :expired do
      remaining { 0 }
      resets_at { 1.minute.ago }
    end
  end
end
