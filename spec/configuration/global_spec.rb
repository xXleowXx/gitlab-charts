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
end
