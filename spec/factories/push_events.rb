FactoryBot.define do
  factory :push_event do
    sequence(:github_event_id) { |n| "evt_#{n}" }
    sequence(:push_id) { |n| 3000 + n }
    ref { "refs/heads/main" }
    add_attribute(:head) { SecureRandom.hex(20) }
    add_attribute(:before) { SecureRandom.hex(20) }
    raw_payload do
      {
        id: github_event_id,
        type: "PushEvent",
        payload: {
          push_id: push_id,
          ref: ref,
          head: attributes[:head],
          before: attributes[:before]
        }
      }
    end
    repository { nil }
    actor { nil }
    enriched_at { nil }

    trait :enriched do
      repository
      actor
      enriched_at { Time.current }
    end

    trait :with_repository do
      repository
    end

    trait :with_actor do
      actor
    end
  end
end
