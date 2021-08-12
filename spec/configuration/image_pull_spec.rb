require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

def should_be_ignored?(resource)
  charts_to_ignore = %w(cert-manager cainjector gitlab-runner grafana postgresql
    prometheus redis nginx-ingress)

  result = charts_to_ignore.select do |chart_name|
    labels = resource.dig('metadata', 'labels')
    (labels&.dig('helm.sh/chart') || labels&.dig('chart'))&.start_with?(chart_name)
  end

  !result.empty?
end

describe 'image configuration' do
  context 'use default values' do
    values = YAML.safe_load %(
      certmanager-issuer:
        email: test@example.com
    )
    template = HelmTemplate.new values

    let(:template) do
      template
    end

    it 'should render the template without error' do
      expect(template.exit_code).to eq(0)
    end

    %w(Deployment StatefulSet Job).each do |kind|
      template.resources_by_kind(kind).each do |key, resource|
        context "resource: #{key}" do
          let(:resource) { resource }

          it 'should have an empty or nil imagePullSecrets' do
            expect(resource.dig('spec', 'template', 'spec', 'imagePullSecrets')).to be_nil | be_empty
          end

          %w(initContainers containers).each do |container_type|
            resource.dig('spec', 'template', 'spec', container_type)&.each do |container|
              context "container: #{container_type}/#{container.dig('name')}" do
                let(:container) { container }

                it 'should use nil or `IfNotPresent` imagePullPolicy' do
                  expect(container.dig('imagePullPolicy')).to be_nil | eq('IfNotPresent')
                end
              end
            end
          end
        end
      end
    end
  end

  context 'deprecated global.imagePullPolicy' do
    values = YAML.safe_load %(
      certmanager-issuer:
        email: test@example.com
      global:
        imagePullPolicy: pp-global
    )

    let(:template) do
      HelmTemplate.new values
    end

    it 'should NOT render the template' do
      expect(template.exit_code).not_to eq(0)
    end
  end

  context 'global imagePullPolicy and imagePullSecrets' do
    values = YAML.safe_load File.read('spec/fixtures/global-image-config.yaml')
    template = HelmTemplate.new values

    let(:template) do
      template
    end

    it 'should render the template without error' do
      expect(template.exit_code).to eq(0)
    end

    %w(Deployment StatefulSet Job).each do |kind|
      template.resources_by_kind(kind).each do |key, resource|
        next if should_be_ignored? resource

        context "resource: #{key}" do
          let(:resource) { resource }

          it 'should use the global imagePullSecrets' do
            expect(resource.dig('spec', 'template', 'spec', 'imagePullSecrets')).to eq([{'name' => 'ps-global'}])
          end

          %w(initContainers containers).each do |container_type|
            resource.dig('spec', 'template', 'spec', container_type)&.each do |container|
              context "container: #{container_type}/#{container.dig('name')}" do
                let(:container) { container }

                it 'should use the global imagePullPolicy', focus: true do
                  expect(container.dig('imagePullPolicy')).to eq('pp-global')
                end
              end
            end
          end
        end
      end
    end
  end

  context 'local imagePullPolicy and imagePullSecrets' do
    values = YAML.safe_load File.read('spec/fixtures/local-image-config.yaml')
    template = HelmTemplate.new values

    let(:template) do
      template
    end

    it 'should render the template without error' do
      expect(template.exit_code).to eq(0)
    end

    %w(Deployment StatefulSet Job).each do |kind|
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

          %w(initContainers containers).each do |container_type|
            resource.dig('spec', 'template', 'spec', container_type)&.each do |container|
              context "container: #{container_type}/#{container.dig('name')}" do
                let(:container) { container }

                it 'should use the local imagePullPolicy' do
                  app_label = resource.dig('metadata', 'labels', 'app')
                  pull_policy = "pp-#{app_label}"

                  pull_policy = 'Never' if app_label == 'gitlab-shell'
                  if container_type == 'initContainers' 
                    if %w(minio registry).include? app_label
                      pull_policy = "#{pull_policy}-init"
                    else
                      pull_policy = 'pp-global-init'
                    end
                  end

                  expect(container.dig('imagePullPolicy')).to eq(pull_policy)
                end
              end
            end
          end
        end
      end
    end
  end
end
