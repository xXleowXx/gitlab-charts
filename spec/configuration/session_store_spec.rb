require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Session store configuration' do
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

  let(:template) { HelmTemplate.new(values) }

  context 'with no set values' do
    let(:values) do
      HelmTemplate.with_defaults({})
    end

    it 'generates the session_store.yml file with default values', :aggregate_failures do
      expect(template.exit_code).to eq(0)
      charts.each_key do |chart|
        session_store_erb = template.dig("ConfigMap/test-#{chart}", 'data', 'session_store.yml.erb')
        session_store_config = YAML.safe_load(session_store_erb)['production']
        expect(session_store_config).to eq({ "session_cookie_token_prefix" => "" })
      end
    end
  end

  context 'with default values' do
    let(:values) do
      HelmTemplate.with_defaults(%(
        global:
          rails:
            session_store:
              session_cookie_token_prefix: ''
    ))
    end

    it 'generates the session_store.yml file with the set default values', :aggregate_failures do
      expect(template.exit_code).to eq(0)
      charts.each_key do |chart|
        session_store_erb = template.dig("ConfigMap/test-#{chart}", 'data', 'session_store.yml.erb')
        session_store_config = YAML.safe_load(session_store_erb)['production']
        expect(session_store_config).to eq({ "session_cookie_token_prefix" => "" })
      end
    end
  end

  context 'with custom session_store configuration' do
    let(:values) do
      HelmTemplate.with_defaults(
        %(
          global:
            rails:
              session_store:
                session_cookie_token_prefix: 'custom_prefix_'
        )
      )
    end

    it 'generates the session_store.yml file with default values', :aggregate_failures do
      expect(template.exit_code).to eq(0)
      charts.each_key do |chart|
        session_store_erb = template.dig("ConfigMap/test-#{chart}", 'data', 'session_store.yml.erb')
        session_store_config = YAML.safe_load(session_store_erb)['production']
        expect(session_store_config).to eq({ "session_cookie_token_prefix" => "custom_prefix_" })
      end
    end
  end
end
