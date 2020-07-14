require 'spec_helper'
require 'helm_template_helper'
require 'yaml'

describe 'Workhorse TOML configuration', :focus => true do
  let(:default_values) do
    { 'certmanager-issuer' => { 'email' => 'test@example.com' } }
  end

  describe 'gitlab.webservice.workhorse.storage.enabled' do
    context 'when true' do
      let(:values) do
        YAML.load(<<~EOS
          gitlab:
            webservice:
              workhorse:
                storage:
                  enabled: true
                  provider: AWS
          EOS
        ).merge(default_values)
      end

      it 'enables workhorse storage' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0)
        expect(t.dig('ConfigMap/test-workhorse-config','data','workhorse-config.toml.erb')).to include("[object_storage]\nenabled = \"true\"")
      end

      it 'uses "AWS" provider' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0)
        expect(t.dig('ConfigMap/test-workhorse-config','data','workhorse-config.toml.erb')).to include("provider = \"AWS\"")
      end

      it 'specifies object storage secrets' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0)
        expect(t.dig('ConfigMap/test-workhorse-config','data','workhorse-config.toml.erb')).to include("aws_access_key_id = \"")
        expect(t.dig('ConfigMap/test-workhorse-config','data','workhorse-config.toml.erb')).to include("aws_secret_access_key = \"")
      end
    end

    context 'when false' do
      let(:values) do
        YAML.load(<<~EOS
          gitlab:
            webservice:
              workhorse:
                storage:
                  enabled: false
                  provider: AWS
          EOS
        ).merge(default_values)
      end

      it 'disables object storage' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0)
        expect(t.dig('ConfigMap/test-workhorse-config','data','workhorse-config.toml.erb')).to include("[object_storage]\nenabled = \"false\"")
      end

      it 'does not specify object storage secrets' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0)
        expect(t.dig('ConfigMap/test-workhorse-config','data','workhorse-config.toml.erb')).not_to include("aws_access_key_id = \"")
        expect(t.dig('ConfigMap/test-workhorse-config','data','workhorse-config.toml.erb')).not_to include("aws_secret_access_key = \"")
      end
    end
  end
end
