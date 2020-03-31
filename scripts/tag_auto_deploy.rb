#!/usr/bin/env ruby
# frozen_string_literal: true

require 'uri'
require 'ostruct'
require_relative 'manage_version'

class TagAutoDeploy
  def initialize
    @opts = OpenStruct.new(
      tag: ENV['AUTO_DEPLOY_TAG'],
      repository_token: ENV['REPOSITORY_PAT'],
      test: ENV['TEST'],
      git_name: 'GitLab Release Tools Bot',
      git_email: 'delivery-team+release-tools@gitlab.com',
      git_remote_url: ENV['CI_REPOSITORY_URL'],
      current_branch: ENV['CI_COMMIT_BRANCH'],
      gitlab_repo: ENV['GITLAB_REPOSITORY']
    )
  end

  def execute
    configure_git

    manage_version

    commit_and_push
  end

  private

  def configure_git
    if dry_run?
      $stderr.puts("Skip git configuration on dry-run mode")
      return
    end

    git('config', '--global', 'user.name', @opts.git_name)
    git('config', '--global', 'user.email', @opts.git_email)

    git('remote', 'set-url', 'origin', git_writable_remote_url)
  end

  def manage_version
    args = [
      '--app-version', @opts.tag,
      '--auto-deploy',
      '--include-subcharts'
    ]

    args << '--dry-run' if dry_run?
    args += ['--gitlab-repo', @opts.gitlab_repo] if @opts.gitlab_repo

    options = VersionOptionsParser.parse(args)
    VersionUpdater.new(options)
  end

  def commit_and_push
    if dry_run?
      $stderr.puts("Skip git operations on dry-run mode")
      return
    end

    git('commit', '-am', "Bump auto-deploy version to #{@opts.tag}")
    git('tag', @opts.tag)
    git('push', 'origin', "HEAD:#{@opts.current_branch}", '--tags')
  end

  def git(*args)
    puts("Running => git #{args.join(' ')}")

    exit(2) unless system('git', *args)
  end

  def dry_run?
    !@opts.test.nil?
  end

  def git_writable_remote_url
    remote = URI(@opts.git_remote_url)
    remote.user = 'gitlab-ci-token'
    remote.password = @opts.repository_token

    remote.to_s
  end
end

# Only auto-run when called as a script, and not included as a lib
if $0 == __FILE__
  unless ENV.key?('CI')
    $stderr.puts 'This script can only be run in CI'
    exit(1)
  end

  TagAutoDeploy.new.execute
end
