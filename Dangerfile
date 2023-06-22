require "gitlab-dangerfiles"

# Documentation reference: https://gitlab.com/gitlab-org/ruby/gems/gitlab-dangerfiles 
Gitlab::Dangerfiles.for_project(self, 'gitlab-chart') do |dangerfiles|
  # Import all plugins from the gem
  dangerfiles.import_plugins

  # Import a defined set of danger rules
  dangerfiles.import_dangerfiles(only: %w[simple_roulette type_label subtype_label changes_size z_retry_link])
end

# danger.import_dangerfile(path: 'scripts/support/changelog')
# danger.import_dangerfile(path: 'scripts/support/metadata')
# danger.import_dangerfile(path: 'scripts/support/reviewers')