# frozen_string_literal: true

if Rails.env.production? && ENV['HONEYBADGER_API_KEY'].present?
  revision = `git rev-parse HEAD 2>/dev/null`.strip
  revision = ENV.fetch('RAILWAY_GIT_COMMIT_SHA', nil) if revision.blank?

  if revision.present?
    Honeybadger.track_deployment(
      environment: Rails.env,
      revision: revision,
      local_username: ENV.fetch('RAILWAY_GIT_AUTHOR', 'railway')
    )
  end
end
