class ActorFetcher
  def initialize(client:)
    @client = client
  end

  def find_or_fetch(event)
    actor_data = extract_actor_data(event)
    return nil unless actor_data

    find_existing(actor_data) || fetch_and_create(actor_data)
  end

  private

  def extract_actor_data(event)
    data = event.raw_payload["actor"]
    return nil unless data&.dig("id")
    data
  end

  def find_existing(actor_data)
    Actor.find_by(github_id: actor_data["id"])
  end

  def fetch_and_create(actor_data)
    full_data = fetch_full_data(actor_data)
    create_actor(full_data || actor_data)
  end

  def fetch_full_data(actor_data)
    url = actor_data["url"]
    return nil unless url
    @client.fetch_actor(url)
  end

  def create_actor(data)
    Actor.create!(
      github_id: data["id"],
      login: data["login"] || data["display_login"],
      avatar_url: data["avatar_url"],
      raw_payload: data
    )
  end
end
