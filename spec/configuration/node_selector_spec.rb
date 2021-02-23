# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'

describe 'Node Selector configuration' do
  let(:default_values) do
    {
      'certmanager-issuer' => { 'email' => 'test@example.com' },
      'gitlab' => { 'kas' => { 'enabled' => 'true' } }, # DELETE THIS WHEN KAS BECOMES ENABLED BY DEFAULT
      'global' => { 'nodeSelector' => { 'region' => 'us-central-1a' } }
    }
  end

  let(:ignored_charts) do
    [
      'Deployment/test-cainjector',
      'Deployment/test-cert-manager',
      'Deployment/test-gitlab-runner',
      'Deployment/test-prometheus-server',
      'Deployment/test-nginx-ingress-controller',
      'Deployment/test-nginx-ingress-default-backend'
    ]
  end

  context 'When setting global nodeSelector' do
    it 'Populates nodeSelector for all deployments' do
      t = HelmTemplate.new(default_values)
      expect(t.exit_code).to eq(0)

      resources_by_kind = t.resources_by_kind('Deployment').reject { |key, _| ignored_charts.include? key }

      resources_by_kind.each do |key, _|
        expect(t.dig(key, 'spec', 'template', 'spec', 'nodeSelector')).to include(default_values['global']['nodeSelector']), key
      end
    end
  end
end
