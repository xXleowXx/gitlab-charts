# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'priorityClass configuration' do
  let(:default_values) do
    HelmTemplate.certmanager_issuer.deep_merge(YAML.safe_load(%(
      global:
        priorityClassName: system-cluster-critical
      gitlab:
        kas:
          enabled: true  # DELETE THIS WHEN KAS BECOMES ENABLED BY DEFAULT
        spamcheck:
          enabled: true  # DELETE THIS WHEN SPAMCHECK BECOMES ENABLED BY DEFAULT
    )))
  end

  let(:ignored_deployments) do
    [
      'Deployment/test-gitlab-runner',
      'Deployment/test-prometheus-server'
    ]
  end

  context 'When setting global priorityClassName' do
    it 'Populates priorityClassName for all deployments and jobs' do
      t = HelmTemplate.new(default_values)
      expect(t.exit_code).to eq(0)

      deployments = t.resources_by_kind('Deployment').reject { |key, _| ignored_deployments.include? key }

      deployments.each do |key, _|
        expect(t.dig(key, 'spec', 'template', 'spec', 'priorityClassName')).to eq('system-cluster-critical')
      end

      jobs = t.resources_by_kind('Job')

      jobs.each do |key, _|
        expect(t.dig(key, 'spec', 'template', 'spec', 'priorityClassName')).to eq('system-cluster-critical')
      end
    end
  end
end
