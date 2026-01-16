class RepositoryFetcher
  def initialize(client:)
    @client = client
  end

  def find_or_fetch(event)
    repo_data = extract_repo_data(event)
    return nil unless repo_data

    find_existing(repo_data) || fetch_and_create(repo_data)
  end

  private

  def extract_repo_data(event)
    data = event.raw_payload["repo"]
    return nil unless data&.dig("id")
    data
  end

  def find_existing(repo_data)
    Repository.find_by(github_id: repo_data["id"])
  end

  def fetch_and_create(repo_data)
    full_data = fetch_full_data(repo_data)
    create_repository(full_data, repo_data)
  end

  def fetch_full_data(repo_data)
    url = repo_data["url"]
    return nil unless url
    @client.fetch_repository(url)
  end

  def create_repository(full_data, fallback_data)
    if full_data
      create_from_api_data(full_data)
    else
      create_from_event_data(fallback_data)
    end
  end

  def create_from_api_data(data)
    Repository.create!(
      github_id: data["id"],
      name: data["name"],
      full_name: data["full_name"],
      raw_payload: data
    )
  end

  def create_from_event_data(data)
    full_name = data["name"]
    name = extract_repo_name(full_name)

    Repository.create!(
      github_id: data["id"],
      name: name,
      full_name: full_name,
      raw_payload: data
    )
  end

  def extract_repo_name(full_name)
    full_name&.split("/")&.last || full_name
  end
end
