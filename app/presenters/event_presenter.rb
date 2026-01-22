class EventPresenter
  def initialize(event)
    @event = event
  end

  def summary
    base_attributes.merge(associations)
  end

  def detail
    base_attributes.merge(raw_payload: @event.raw_payload).merge(associations)
  end

  def self.summary(event)
    new(event).summary
  end

  def self.detail(event)
    new(event).detail
  end

  private

  def base_attributes
    {
      id: @event.id,
      github_event_id: @event.github_event_id,
      push_id: @event.push_id,
      ref: @event.ref,
      head: @event.head,
      before: @event.before,
      enriched: @event.enriched?,
      enriched_at: @event.enriched_at,
      created_at: @event.created_at
    }
  end

  def associations
    {
      actor: @event.actor ? ActorPresenter.summary(@event.actor) : nil,
      repository: @event.repository ? RepositoryPresenter.summary(@event.repository) : nil
    }
  end
end
