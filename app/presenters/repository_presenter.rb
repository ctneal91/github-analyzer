class RepositoryPresenter
  def initialize(repository)
    @repository = repository
  end

  def summary
    {
      id: @repository.id,
      github_id: @repository.github_id,
      name: @repository.name,
      full_name: @repository.full_name
    }
  end

  def for_list
    summary.merge(
      event_count: @repository.try(:event_count) || 0,
      created_at: @repository.created_at
    )
  end

  def self.summary(repository)
    new(repository).summary
  end

  def self.for_list(repository)
    new(repository).for_list
  end
end
