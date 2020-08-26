require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'gitlab.yml.erb configuration' do
  let(:default_values) do
    {
      'certmanager-issuer' => { 'email' => 'test@example.com' }
    }
  end

  context 'when incomingEmail is disabled' do
    it 'does not populate the gitlab.yml.erb' do
      t = HelmTemplate.new(default_values)
      expect(t.dig(
        'ConfigMap/test-sidekiq',
        'data',
        'gitlab.yml.erb'
      )).not_to include('incoming_email')
      expect(t.dig(
        'ConfigMap/test-webservice',
        'data',
        'gitlab.yml.erb'
      )).not_to include('incoming_email')
    end
  end

  context 'when incomingEmail is enabled' do
    let(:required_values) do
      {
        'global' => {
          'appConfig' => {
            'incomingEmail' => {
              'enabled' => true,
              'password' => {
                'secret' => 'incomingEmail-v1',
                'key' => 'password'
              },
            }
          }
        }
      }.merge(default_values)
    end

    let(:missing_values) do
      {
        'global' => {
          'appConfig' => {
            'incomingEmail' => {
              'enabled' => true
            }
          }
        }
      }.merge(default_values)
    end

    it 'populates the gitlab.yml.erb' do
      t = HelmTemplate.new(required_values)
      expect(t.dig(
        'ConfigMap/test-sidekiq',
        'data',
        'gitlab.yml.erb'
      )).to include('incoming_email')
      expect(t.dig(
        'ConfigMap/test-webservice',
        'data',
        'gitlab.yml.erb'
      )).to include('incoming_email')
    end

    it 'fails when we are missing a required value' do
      t = HelmTemplate.new(missing_values)
      expect(t.exit_code).not_to eq(0)
      expect(t.stderr).to include(
        'set `global.appConfig.incomingEmail.password.secret'
      )
    end
  end
end
