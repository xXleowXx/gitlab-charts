require 'spec_helper'
require 'helm_template_helper'
require 'yaml'

TARGET_KINDS = %w[Deployment StatefulSet DaemonSet Job].freeze
CONTAINER_TYPES = %w[initContainers containers].freeze
MIRRORED_IMAGES = %w[busybox ingress-nginx defaultbackend].freeze # https://gitlab.com/gitlab-org/cloud-native/mirror/images/-/blob/main/mirrored-images
EXTERNAL_CHARTS = %w[
  certmanager gitlab-runner grafana postgresql prometheus redis
].freeze

def targeted_resource_kind?(resource)
  TARGET_KINDS.include? resource['kind']
end

def should_be_ignored?(resource)
  result = EXTERNAL_CHARTS.select do |chart_name|
    labels = resource.dig('metadata', 'labels')
    (labels&.dig('helm.sh/chart') || labels&.dig('chart'))&.start_with?(chart_name)
  end

  !result.empty?
end

describe 'image path configuration' do
  context 'using default values' do
    begin
      template = HelmTemplate.from_string
    rescue StandardError
      # Skip these examples when helm or chart dependencies are missing
      next
    end

    let(:template) do
      template
    end

    it 'should render the template without error' do
      expect(template.exit_code).to eq(0)
    end

    template.mapped.select { |_, resource| targeted_resource_kind?(resource) && !should_be_ignored?(resource) }.each do |key, resource|
      context "resource: #{key}" do
        let(:resource) { resource }

        CONTAINER_TYPES.each do |container_type|
          resource.dig('spec', 'template', 'spec', container_type)&.each do |container|
            context "container: #{container_type}/#{container&.dig('name')}" do
              let(:container) { container }

              container_name = container&.dig('name')
              container_image = container&.dig('image')

              # We only control MinIO's `configure` initContainer.
              next if container_name.include?('minio')

              registry = 'registry.gitlab.com'
              repository = 'gitlab-org/build/cng'
              repository = 'gitlab-org/cloud-native/mirror/images' if MIRRORED_IMAGES.any? { |i| container_image.include? i }

              it 'should use default registry and repository' do
                expect(container&.dig('image')).to start_with("#{registry}/#{repository}/")
              end
            end
          end
        end
      end
    end
  end

  context 'global image registry and repository' do
    begin
      template = HelmTemplate.from_file 'spec/fixtures/global-image-config.yaml'
    rescue StandardError
      # Skip these examples when helm or chart dependencies are missing
      next
    end

    let(:template) do
      template
    end

    it 'should render the template without error' do
      expect(template.exit_code).to eq(0)
    end

    template.mapped.select { |_, resource| targeted_resource_kind?(resource) && !should_be_ignored?(resource) }.each do |key, resource|
      context "resource: #{key}" do
        let(:resource) { resource }

        CONTAINER_TYPES.each do |container_type|
          resource.dig('spec', 'template', 'spec', container_type)&.each do |container|
            context "container: #{container_type}/#{container&.dig('name')}" do
              let(:container) { container }

              container_name = container&.dig('name')

              # We only control MinIO's `configure` initContainer.
              next if container_name.include?('minio')

              it 'should use the global registry and repository' do
                case container_name
                when 'configure', 'run-check'
                  registry = 'global.busybox.registry.com'
                  repository = 'global-busybox-repo'
                else
                  registry = 'global.registry.com'
                  repository = 'global-repo'
                end

                expect(container&.dig('image')).to start_with("#{registry}/#{repository}/")
              end
            end
          end
        end
      end
    end
  end

  context 'local registry and repository' do
    begin
      template = HelmTemplate.from_file 'spec/fixtures/local-image-config.yaml'
    rescue StandardError
      # Skip these examples when helm or chart dependencies are missing
      next
    end

    let(:template) do
      template
    end

    it 'should render the template without error' do
      expect(template.exit_code).to eq(0)
    end

    template.mapped.select { |_, resource| targeted_resource_kind?(resource) && !should_be_ignored?(resource) }.each do |key, resource|
      context "resource: #{key}" do
        let(:resource) { resource }

        CONTAINER_TYPES.each do |container_type|
          resource.dig('spec', 'template', 'spec', container_type)&.each do |container|
            context "container: #{container_type}/#{container&.dig('name')}" do
              let(:container) { container }

              it 'should use the local registry' do
                container_name = container&.dig('name')

                # We only control MinIO's `configure` initContainer.
                next if container_name.include?('minio')

                app_label = resource.dig('metadata', 'labels', 'app')

                app_label = 'kubectl' if app_label == 'certmanager-issuer' ||
                  resource&.dig('metadata', 'name')&.include?('shared-secrets')

                app_label = case container_name
                            when 'certificates'
                              'certificates'
                            when 'configure'
                              'busybox'
                            when 'gitlab-workhorse'
                              'workhorse'
                            when 'run-check'
                              'upgradecheck'
                            else
                              app_label
                            end

                registry = "#{app_label}.registry.com"
                repository = "#{app_label}-repo"

                expect(container&.dig('image')).to start_with("#{registry}/#{repository}/")
              end
            end
          end
        end
      end
    end
  end
end
