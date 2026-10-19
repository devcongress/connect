# Chooses one public, non-curated sample of projects for the homepage each day.
class HomepageProjectSelector
  LIMIT = 3
  CONTEXT = "homepage-projects"

  def self.call(**) = new(**).call

  def initialize(
    scope: Showcase::Project.visible_to(nil),
    period: Date.current,
    limit: LIMIT,
    secret: Rails.application.secret_key_base
  )
    @scope = scope
    @period = period
    @limit = limit
    @secret = secret
  end

  def call
    selected_ids = DeterministicDailyOrder.call(
      @scope.ids,
      context: CONTEXT,
      period: @period,
      secret: @secret
    ).first(@limit)

    projects = @scope.where(id: selected_ids)
      .includes(:owner, :skills, confirmed_contributors: :profile)
      .index_by(&:id)
    selected_ids.filter_map { |id| projects[id] }
  end
end
