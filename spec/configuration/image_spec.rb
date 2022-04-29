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

describe 'image configuration' do
  context 'deprecated global.imagePullPolicy' do
    begin
      template = HelmTemplate.from_string %(
        global:
          imagePullPolicy: pp-global
      )
    rescue StandardError
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

        it 'should have an empty or nil imagePullSecrets' do
          expect(resource.dig('spec', 'template', 'spec', 'imagePullSecrets')).to be_nil | be_empty
        end

        CONTAINER_TYPES.each do |container_type|
          resource.dig('spec', 'template', 'spec', container_type)&.each do |container|
            context "container: #{container_type}/#{container&.dig('name')}" do
              let(:container) { container }

              container_name = container&.dig('name')
              container_image = container&.dig('image')

              # We only control MinIO's `configure` initContainer.
              next if container_name.include?('minio')

              repository = 'registry.gitlab.com/gitlab-org/build/cng'
              repository = 'registry.gitlab.com/gitlab-org/cloud-native/mirror/images' if MIRRORED_IMAGES.any? { |i| container_image.include? i }

              it 'should use default repository' do
                expect(container&.dig('image')).to start_with("#{repository}/")
              end

              it 'should use nil or `IfNotPresent` imagePullPolicy' do
                expect(container&.dig('imagePullPolicy')).to be_nil | eq('IfNotPresent')
              end
            end
          end
        end
      end
    end
  end

  context 'global image settings' do
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

        it 'should use the global imagePullSecrets' do
          expect(resource.dig('spec', 'template', 'spec', 'imagePullSecrets')).to eq(['name' => 'ps-global'])
        end

        CONTAINER_TYPES.each do |container_type|
          resource.dig('spec', 'template', 'spec', container_type)&.each do |container|
            context "container: #{container_type}/#{container&.dig('name')}" do
              let(:container) { container }

              container_name = container&.dig('name')

              # We only control MinIO's `configure` initContainer.
              next if container_name.include?('minio')

              it 'should use the global registry' do
                case container_name
                when 'configure', 'run-check'
                  registry = 'global.busybox.registry.com'
                else
                  registry = 'global.registry.com'
                end

                expect(container&.dig('image')).to start_with("#{registry}/")
              end

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

  context 'local image settings' do
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

              it 'should use the local repository' do
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
                            else
                              app_label
                            end

                repository = "#{app_label}.registry.com/#{app_label}-repo"

                expect(container&.dig('image')).to start_with(repository)
              end

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
