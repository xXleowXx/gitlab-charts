require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'geo-logcursor configuration' do
  let(:default_values) do
    {
      # provide required setting
      'certmanager-issuer' => { 'email' => 'test@example.com' },
      'global' => {
        'geo' => {
          'enabled' => true,
          'role' => 'primary'
        },
        'hosts' => {
          'domain' => 'example.com'
        },
        'psql' => {
          'host' => 'localhost',
          'password' => {
            'secret' => 'foobar'
          }
        }
      },
      'postgres' => {
        'install' => false
      }
    }
  end

  context 'When customer provides additional labels' do
    let(:values) do
      {
        'global' => {
          'common' => {
            'labels' => {
              'global' => "global",
              'foo' => "global"
            }
          },
          'pod' => {
            'labels' => {
              'global_pod' => true
            }
          },
          'service' => {
            'labels' => {
              'global_service' => true
            }
          }
        },
        'gitlab' => {
          'geo-logcursor' => {
            'common' => {
              'labels' => {
                'global' => 'geo-logcursor',
                'geo-logcursor' => 'geo-logcursor'
              }
            },
            'podLabels' => {
              'pod' => true,
              'global' => 'pod'
            },
            'serviceLabels' => {
              'service' => true,
              'global' => 'service'
            }
          }
        }
      }.deep_merge(default_values)
    end
    it 'Populates the additional labels in the expected manner' do
      t = HelmTemplate.new(values)
      binding.pry
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      expect(t.dig('ConfigMap/test-geo-logcursor', 'metadata', 'labels')).to include('global' => 'geo-logcursor')
      expect(t.dig('Deployment/test-geo-logcursor', 'metadata', 'labels')).to include('foo' => 'global')
      expect(t.dig('Deployment/test-geo-logcursor', 'metadata', 'labels')).to include('global' => 'pod')
      expect(t.dig('Deployment/test-geo-logcursor', 'metadata', 'labels')).to include('global_pod' => true)
      expect(t.dig('Deployment/test-geo-logcursor', 'metadata', 'labels')).not_to include('global' => 'geo-logcursor')
      expect(t.dig('Deployment/test-geo-logcursor', 'metadata', 'labels')).not_to include('global' => 'global')
      expect(t.dig('Deployment/test-geo-logcursor', 'spec', 'template', 'metadata', 'labels')).to include('global' => 'pod')
      expect(t.dig('Deployment/test-geo-logcursor', 'spec', 'template', 'metadata', 'labels')).to include('global_pod' => true)
      expect(t.dig('Deployment/test-geo-logcursor', 'spec', 'template', 'metadata', 'labels')).to include('pod' => true)
      expect(t.dig('Service/test-geo-logcursor', 'metadata', 'labels')).to include('global' => 'service')
      expect(t.dig('Service/test-geo-logcursor', 'metadata', 'labels')).to include('global_service' => true)
      expect(t.dig('Service/test-geo-logcursor', 'metadata', 'labels')).to include('service' => true)
      expect(t.dig('Service/test-geo-logcursor', 'metadata', 'labels')).not_to include('global' => 'global')
      expect(t.dig('ServiceAccount/test-geo-logcursor', 'metadata', 'labels')).to include('global' => 'geo-logcursor')
    end
  end
end
