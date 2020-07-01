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
        {
          'gitlab' => {
            'webservice' => {
              'workhorse' => {
                'storage' => {
                  'enabled' => true
                }
              }
            }
          }
        }.merge(default_values)
      end

      it 'enables workhorse storage' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0)
        expect(t.dig('ConfigMap/test-workhorse-config','data','workhorse-config.toml.erb')).to include("[object_storage]\nenabled = true")
      end

      it 'uses "AWS" provider' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0)
        expect(t.dig('ConfigMap/test-workhorse-config','data','workhorse-config.toml.erb')).to include("provider = \"AWS\"")
      end

      context 'and object storage secrets not specified' do

      end
    end

    context 'when false' do
      let(:values) do
        {
          'gitlab' => {
            'webservice' => {
              'workhorse' => {
                'storage' => {
                  'enabled' => false
                }
              }
            }
          }
        }.merge(default_values)
      end

      it 'disables workhorse storage' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0)
        expect(t.dig('ConfigMap/test-workhorse-config','data','workhorse-config.toml.erb')).to include("[object_storage]\nenabled = false")
      end

      context 'and object storage secrets not specified' do

      end
    end

  end

  describe 'gitlab.webservice.workhorse.storage.password' do

  end

end