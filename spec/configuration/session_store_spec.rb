require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'ClickHouse configuration' do
  let(:charts) do
    {
      'webservice' => {
        'identifier' => 'test-webservice-default',
        'init_mount' => 'init-webservice-secrets'
      },
      'sidekiq' => {
        'identifier' => 'test-sidekiq-all-in-1-v2',
        'init_mount' => 'init-sidekiq-secrets'
      },
      'toolbox' => {
        'identifier' => 'test-toolbox',
        'init_mount' => 'init-toolbox-secrets'
      }
    }
  end

  let(:values) do
    HelmTemplate.with_defaults(%(
        global:
          rails:
            session_store:
              session_cookie_token_prefix: ''
    ))
  end

  let(:template) { HelmTemplate.new(values) }

  it 'generates the session_store.yml file with default values', :aggregate_failures do
    expect(template.exit_code).to eq(0)
    charts.each_key do |chart|
      session_store_erb = template.dig("ConfigMap/test-#{chart}", 'data', 'sessoin_store.yml.erb')
      expect(session_store_erb).to be_nil
    end
  end
end
