require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

NODE_AFFINITY_DEPLOYMENTS = %w(Deployment/test-registry).freeze

describe 'global affinity configuration' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      global:
        nodeAffinity: "hard"
        antiAffinity: "soft"
        affinity:
          nodeAffinity:
            key: "test.com/zone"
            values:
            - us-east1-a
            - us-east1-b
          podAntiAffinity:
            topologyKey: "test.com/hostname"
    ))
  end

  let(:ignored_deployments) do
    [
      'Deployment/test-certmanager',
      'Deployment/test-certmanager-cainjector',
      'Deployment/test-certmanager-webhook',
      'Deployment/test-cert-manager',
      'Deployment/test-cert-manager-cainjector',
      'Deployment/test-cert-manager-webhook',
      'Deployment/test-gitlab-runner',
      'Deployment/test-minio',
      'Deployment/test-nginx-ingress-controller',
      'Deployment/test-prometheus-server',
    ]
  end

  let(:supported_node_affinity_deployments) do
    [
      'Deployment/test-registry'
    ]
  end

 # context 'when enabling nodeAffinity' do
 #   it 'populates nodeAffinity rules for all Deployments' do
 #     t = HelmTemplate.new(default_values)
 #     expect(t.exit_code).to eq(0)

  #     deployments = t.resources_by_kind('Deployment').select { |key, _| supported_node_affinity_deployments.include? key }

 #     deployments.each do |key, _|
 #       expect(t.dig(key, 'spec', 'template', 'spec', 'template', 'affinity', 'nodeAffinity')).should exist
 #     end
 #   end
 # end

  context 'when overriding antiAffinity' do
    it 'applies to all Deployments' do
       t = HelmTemplate.new(default_values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

      deployments = t.resources_by_kind('Deployment').reject { |key, _| ignored_deployments.include? key }

      deployments.each do |key, _|
        expect(t.dig(key, 'spec', 'template', 'spec', 'affinity', 'podAntiAffinity', 'preferredDuringSchedulingIgnoredDuringExecution')).to be_present
      end
    end
  end
end

describe 'local affinity configuration' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      global:
        nodeAffinity: "hard"
        antiAffinity: "soft"
        affinity:
          nodeAffinity:
            key: "test.com/zone"
            values:
            - us-east1-a
            - us-east1-b
          podAntiAffinity:
            topologyKey: "test.com/hostname"
      registry:
        nodeAffinity: "soft"
        antiAffinity: "hard"
        affinity:
          podAntiAffinity:
            topologyKey: "override.com/hostname"
    ))
  end

  let(:ignored_deployments) do
    [
      'Deployment/test-certmanager',
      'Deployment/test-certmanager-cainjector',
      'Deployment/test-certmanager-webhook',
      'Deployment/test-cert-manager',
      'Deployment/test-cert-manager-cainjector',
      'Deployment/test-cert-manager-webhook',
      'Deployment/test-gitlab-runner',
      'Deployment/test-minio',
      'Deployment/test-nginx-ingress-controller',
      'Deployment/test-prometheus-server',
    ]
  end

  context 'when setting a local antiAffinity override' do
    it 'applies to a single Deployment' do
      t = HelmTemplate.new(default_values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

      deployments = t.resources_by_kind('Deployment').reject { |key, _| ignored_deployments.include? key }

      deployments.each do |key, _|
        if key == 'Deployment/test-registry'
          expect(t.dig(key, 'spec', 'template', 'spec', 'affinity', 'podAntiAffinity', 'requiredDuringSchedulingIgnoredDuringExecution')).to be_present
          expect(t.dig(key, 'spec', 'template', 'spec', 'affinity', 'podAntiAffinity', 'preferredDuringSchedulingIgnoredDuringExecution')).not_to be_present
          expect(t.dig(key, 'spec', 'template', 'spec', 'affinity', 'podAntiAffinity', 'requiredDuringSchedulingIgnoredDuringExecution')[0]['topologyKey']).to eq('override.com/hostname')
        else
          expect(t.dig(key, 'spec', 'template', 'spec', 'affinity', 'podAntiAffinity', 'preferredDuringSchedulingIgnoredDuringExecution')).to be_present
          expect(t.dig(key, 'spec', 'template', 'spec', 'affinity', 'podAntiAffinity', 'requiredDuringSchedulingIgnoredDuringExecution')).not_to be_present
          expect(t.dig(key, 'spec', 'template', 'spec', 'affinity', 'podAntiAffinity', 'preferredDuringSchedulingIgnoredDuringExecution')[0]['podAffinityTerm']['topologyKey']).to eq('test.com/hostname')
        end
      end
    end
  end
end
