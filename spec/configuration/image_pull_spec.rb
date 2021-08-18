require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

CHARTS_TO_IGNORE = %w[
  certmanager gitlab-runner grafana postgresql prometheus redis nginx-ingress
].freeze
FORKED_CHARTS = %w[minio registry].freeze
TARGET_KINDS = %w[Deployment StatefulSet Job].freeze
CONTAINER_TYPES = %w[initContainers containers].freeze

def should_be_ignored?(resource)
  result = CHARTS_TO_IGNORE.select do |chart_name|
    labels = resource.dig('metadata', 'labels')
    (labels&.dig('helm.sh/chart') || labels&.dig('chart'))&.start_with?(chart_name)
  end

  !result.empty?
end

describe 'image configuration' do
  context 'use default values' do
    begin
      template = HelmTemplate.from_string
    rescue
      # Skip these examples when helm or chart dependencies are missing
      next
    end

    let(:template) do
      template
    end

    it 'should render the template without error' do
      expect(template.exit_code).to eq(0)
    end

    TARGET_KINDS.each do |kind|
      template.resources_by_kind(kind).each do |key, resource|
        context "resource: #{key}" do
          let(:resource) { resource }

          it 'should have an empty or nil imagePullSecrets' do
            expect(resource.dig('spec', 'template', 'spec', 'imagePullSecrets')).to be_nil | be_empty
          end

          CONTAINER_TYPES.each do |container_type|
            resource.dig('spec', 'template', 'spec', container_type)&.each do |container|
              context "container: #{container_type}/#{container&.dig('name')}" do
                let(:container) { container }

                it 'should use nil or `IfNotPresent` imagePullPolicy' do
                  expect(container&.dig('imagePullPolicy')).to be_nil | eq('IfNotPresent')
                end
              end
            end
          end
        end
      end
    end
  end

  context 'deprecated global.imagePullPolicy' do
    begin
      template = HelmTemplate.from_string %(
        global:
          imagePullPolicy: pp-global
      )
    rescue
      # Skip these examples when helm or chart dependencies are missing
      next
    end

    let(:template) do
      template
    end

    it 'should NOT render the template' do
      expect(template.exit_code).not_to eq(0)
    end
  end

  context 'global imagePullPolicy and imagePullSecrets' do
    begin
      template = HelmTemplate.from_file 'spec/fixtures/global-image-config.yaml'
    rescue
      # Skip these examples when helm or chart dependencies are missing
      next
    end

    let(:template) do
      template
    end

    it 'should render the template without error' do
      expect(template.exit_code).to eq(0)
    end

    TARGET_KINDS.each do |kind|
      template.resources_by_kind(kind).each do |key, resource|
        next if should_be_ignored? resource

        context "resource: #{key}" do
          let(:resource) { resource }

          it 'should use the global imagePullSecrets' do
            expect(resource.dig('spec', 'template', 'spec', 'imagePullSecrets')).to eq(['name' => 'ps-global'])
          end

          CONTAINER_TYPES.each do |container_type|
            resource.dig('spec', 'template', 'spec', container_type)&.each do |container|
              context "container: #{container_type}/#{container&.dig('name')}" do
                let(:container) { container }

                it 'should use the global imagePullPolicy' do
                  pull_policy = 'pp-global'

                  pull_policy = 'pp-busybox' if container_type == 'initContainers' &&
                    container&.dig('name') == 'configure'

                  expect(container&.dig('imagePullPolicy')).to eq(pull_policy)
                end
              end
            end
          end
        end
      end
    end
  end

  context 'local imagePullPolicy and imagePullSecrets' do
    begin
      template = HelmTemplate.from_file 'spec/fixtures/local-image-config.yaml'
    rescue
      # Skip these examples when helm or chart dependencies are missing
      next
    end

    let(:template) do
      template
    end

    it 'should render the template without error' do
      expect(template.exit_code).to eq(0)
    end

    TARGET_KINDS.each do |kind|
      template.resources_by_kind(kind).each do |key, resource|
        next if should_be_ignored? resource

        context "resource: #{key}" do
          let(:resource) { resource }

          next if should_be_ignored? resource

          it 'should have both the global and local imagePullSecrets' do
            app_label = resource.dig('metadata', 'labels', 'app')
            expect(resource.dig('spec', 'template', 'spec', 'imagePullSecrets')).to \
              include('name' => 'ps-global')
            expect(resource.dig('spec', 'template', 'spec', 'imagePullSecrets')).to \
              include('name' => "ps-#{app_label}") | include('name' => "ps-kubectl")
          end

          CONTAINER_TYPES.each do |container_type|
            resource.dig('spec', 'template', 'spec', container_type)&.each do |container|
              context "container: #{container_type}/#{container&.dig('name')}" do
                let(:container) { container }

                it 'should use the local imagePullPolicy' do
                  app_label = resource.dig('metadata', 'labels', 'app')

                  app_label = 'kubectl' if app_label == 'certmanager-issuer' ||
                    resource&.dig('metadata', 'name')&.include?('shared-secrets')

                  pull_policy = "pp-#{app_label}"

                  pull_policy = 'Never' if app_label == 'gitlab-shell'
                  pull_policy = case container&.dig('name')
                                when 'certificates'
                                  'pp-certificates'
                                when 'configure'
                                  "#{pull_policy}-init"
                                else
                                  pull_policy
                                end if container_type == 'initContainers'

                  expect(container&.dig('imagePullPolicy')).to eq(pull_policy)
                end
              end
            end
          end
        end
      end
    end
  end
end
