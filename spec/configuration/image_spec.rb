require 'spec_helper'
require 'helm_template_helper'
require 'yaml'

describe 'image configuration' do
  let(:included_charts) do
    [
      'Deployment/test-spamcheck'
    ]
  end

  let(:default_values) do
    HelmTemplate.with_defaults(%(
      global:
        spamcheck:
          enabled: true
    ))
  end

  let(:global_image_registry_values) do
    YAML.safe_load(%(
    global:
      image:
        registry: custom.registry.com
    )).deep_merge(default_values)
  end

  context 'using default values' do
    it 'uses the default registry in the image path' do
      t = HelmTemplate.new(default_values)
      expect(t.exit_code).to eq(0)

      resources_by_kind = t.resources_by_kind('Deployment').select { |key, _| included_charts.include? key }

      resources_by_kind.each do |key, _|
        expect(t.find_image(key, 'spamcheck')).to start_with('registry.gitlab.com')
      end
    end
  end

  context 'using global image values' do
    it 'uses the global registry in the image path' do
      t = HelmTemplate.new(global_image_registry_values)
      expect(t.exit_code).to eq(0)

      resources_by_kind = t.resources_by_kind('Deployment').select { |key, _| included_charts.include? key }

      resources_by_kind.each do |key, _|
        expect(t.find_image(key, 'spamcheck')).to start_with('custom.registry.com')
      end
    end
  end

  context 'using local and global image values' do
    let(:local_image_registry_values) do
      YAML.safe_load(%(
      gitlab:
        spamcheck:
          image:
            registry: spamcheck.registry.com
      )).deep_merge(global_image_registry_values)
    end

    it 'uses the local registry in the image path' do
      t = HelmTemplate.new(local_image_registry_values)
      expect(t.exit_code).to eq(0)

      resources_by_kind = t.resources_by_kind('Deployment').select { |key, _| included_charts.include? key }

      resources_by_kind.each do |key, _|
        expect(t.find_image(key, 'spamcheck')).to start_with('spamcheck.registry.com')
      end
    end
  end
end
