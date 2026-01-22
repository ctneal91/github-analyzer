class ActorPresenter
  def initialize(actor)
    @actor = actor
  end

  def summary
    {
      id: @actor.id,
      github_id: @actor.github_id,
      login: @actor.login,
      avatar_url: @actor.avatar_url
    }
  end

  def for_list
    summary.merge(
      event_count: @actor.try(:event_count) || 0,
      created_at: @actor.created_at
    )
  end

  def self.summary(actor)
    new(actor).summary
  end

  def self.for_list(actor)
    new(actor).for_list
  end
end
