# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'

describe 'Node Selector configuration' do
  let(:default_values) do
    {
      'certmanager-issuer' => { 'email' => 'test@example.com' },
      'global' => {
        'gitlab' => {
          'kas' => { 'enabled' => 'true' }, # DELETE THIS WHEN KAS BECOMES ENABLED BY DEFAULT
          'pages' => { 'enabled' => 'true' },
          'praefect' => { 'enabled' => 'true' }
        },
        'nodeSelector' => { 'region' => 'us-central-1a' }
      }
    }
  end

  let(:ignored_charts) do
    [
      'Deployment/test-cainjector',
      'Deployment/test-cert-manager',
      'Deployment/test-gitlab-runner',
      'Deployment/test-prometheus-server',
      'StatefulSet/test-postgresql',
      'StatefulSet/test-redis-master'
    ]
  end

  context 'When setting global nodeSelector' do
    it 'Populates nodeSelector for all resources' do
      t = HelmTemplate.new(default_values)
      expect(t.exit_code).to eq(0)

      resources = [
        *t.resources_by_kind('Deployment'),
        *t.resources_by_kind('DaemonSet'),
        *t.resources_by_kind('StatefulSet')
      ]
      .to_h.reject { |key, _| ignored_charts.include? key }

      resources.each do |key, _|
        expect(t.dig(key, 'spec', 'template', 'spec', 'nodeSelector')).to include(default_values['global']['nodeSelector']), key
      end
    end
  end
end
