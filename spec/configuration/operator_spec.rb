require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'operator configuration' do
  let(:default_values) do
    {
      'certmanager-issuer' => { 'email' => 'test@example.com' },
      'global' => {
        'operator' => {
          'enabled' => true
        }
      }
    }
  end

  context 'When customer provides additional labels' do
    let(:values) do
      {
        'global' => {
          'common' => {
            'labels' => {
              'global' => 'global',
              'foo' => 'global'
            }
          },
          'pod' => {
            'labels' => {
              'global_pod' => true
            }
          }
        },
        'gitlab' => {
          'operator' => {
            'common' => {
              'labels' => {
                'global' => 'operator',
                'operator' => 'operator'
              }
            },
            'podLabels' => {
              'pod' => true,
              'global' => 'pod'
            }
          }
        }
      }.deep_merge(default_values)
    end

    it 'Populates the additional labels in the expected manner' do
      t = HelmTemplate.new(values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      expect(t.dig('Deployment/test-operator', 'metadata', 'labels')).to include('foo' => 'global')
      expect(t.dig('Deployment/test-operator', 'metadata', 'labels')).to include('global' => 'operator')
      expect(t.dig('Deployment/test-operator', 'metadata', 'labels')).not_to include('global' => 'global')
      expect(t.dig('Deployment/test-operator', 'spec', 'template', 'metadata', 'labels')).to include('global' => 'pod')
      expect(t.dig('Deployment/test-operator', 'spec', 'template', 'metadata', 'labels')).to include('pod' => true)
      expect(t.dig('Deployment/test-operator', 'spec', 'template', 'metadata', 'labels')).to include('global_pod' => true)
      expect(t.dig('GitLab/test-operator', 'metadata', 'labels')).to include('global' => 'operator')
      expect(t.dig('ClusterRole/test-operator', 'metadata', 'labels')).to include('global' => 'operator')
      expect(t.dig('ClusterRoleBinding/test-operator', 'metadata', 'labels')).to include('global' => 'operator')
      expect(t.dig('ServiceAccount/test-operator', 'metadata', 'labels')).to include('global' => 'operator')
    end
  end
end
