require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'global configuration' do
  let(:default_values) do
    {
      # provide required setting
      'certmanager-issuer' => { 'email' => 'test@example.com' },
      'global' => {}
    }
  end

  context 'required settings' do
    it 'successfully creates a helm release' do
      t = HelmTemplate.new(default_values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
    end
  end

  context 'default settings' do
    it 'fails to create a helm release' do
      t = HelmTemplate.new({})
      expect(t.exit_code).to eq(256), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
    end
  end

  describe 'registry notifications enabled' do
    let(:registry_notifications) do
      {
        'global' => {
          'registry' => {
            'notificationSecret' => {
              'enabled' => true
            }
          }
        }
      }.deep_merge(default_values)
    end

    it 'configures the consumption of the secret' do
      t = HelmTemplate.new(registry_notifications)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      expect(t.find_secret('Deployment/test-sidekiq-all-in-1-v1', 'init-sidekiq-secrets', 'test-registry-notification')).to be true
      expect(t.find_secret('Deployment/test-webservice-default', 'init-webservice-secrets', 'test-registry-notification')).to be true
      expect(t.find_secret('Deployment/test-task-runner', 'init-task-runner-secrets', 'test-registry-notification')).to be true
    end
  end

  describe 'registry and geo sync enabled' do
    let(:registry_notifications) do
      {
        'global' => {
          'geo' => {
            'enabled' => true,
            'role' => 'primary',
            'registry' => {
              'syncEnabled' => true
            }
          },
          'postgresql' => {
            'install' => false
          },
          'psql' => {
            'host' => 'geo-1.db.example.com',
            'port' => '5432',
            'password' => {
              'secret' => 'geo',
              'key' => 'postgresql-password'
            }
          },
          'registry' => {
            'notifications' => {
              'endpoints' => [{
                'name' => 'FooListener',
                'url' => 'https://foolistener.com/event',
                'timeout' => '500ms',
                'threshold' => '10',
                'backoff' => '1s',
                'headers' => {
                  'FooBar' => ['1', '2'],
                  'Authorization' => {
                    'secret' => 'gitlab-registry-authorization-header'
                  },
                  'SpecificPassword' => {
                    'secret' => 'gitlab-registry-specific-password',
                    'key' => 'password'
                  }
                }
              }]
            }
          }
        }
      }.deep_merge(default_values)
    end

    it 'configures the consumption of the secret' do
      t = HelmTemplate.new(registry_notifications)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

      # The below is ugly, both code wise, as well as informing the user testing WHAT is wrong...
      foo = t.dig('ConfigMap/test-registry', 'data', 'config.yml')
      bar = YAML.load(foo) # can't use safe_load here...

      binding.pry
      # Testing that we don't accidentally blow away a customization
      expect(bar['notifications']['endpoints'].any? { |item| item['name'] == 'FooListener' }).to eq(true)

      # With geo enabled && syncing of the registry enabled, we insert this notifier
      expect(bar['notifications']['endpoints'].any? { |item| item['name'] == 'geo_event' }).to eq(true)
    end
  end

  describe 'registry and geo sync enabled' do
    let(:registry_notifications) do
      {
        'global' => {
          'geo' => {
            'enabled' => true,
            'role' => 'primary',
            'registry' => {
              'syncEnabled' => true
            }
          },
          'postgresql' => {
            'install' => false
          },
          'psql' => {
            'host' => 'geo-1.db.example.com',
            'port' => '5432',
            'password' => {
              'secret' => 'geo',
              'key' => 'postgresql-password'
            }
          }
        }
      }.deep_merge(default_values)
    end

    it 'configures the consumption of the secret' do
      t = HelmTemplate.new(registry_notifications)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

      # The below is ugly, both code wise, as well as informing the user testing WHAT is wrong...
      foo = t.dig('ConfigMap/test-registry', 'data', 'config.yml')
      bar = YAML.load(foo) # can't use safe_load here...l TODO fix this

      binding.pry
      # Testing that we don't accidentally blow away a customization
      expect(bar['notifications']['endpoints'].any? { |item| item['name'] == 'FooListener' }).to eq(false)

      # With geo enabled && syncing of the registry enabled, we insert this notifier
      expect(bar['notifications']['endpoints'].any? { |item| item['name'] == 'geo_event' }).to eq(true)
      # TODO Add test to ensure we don't duplicate things
    end
  end
end
