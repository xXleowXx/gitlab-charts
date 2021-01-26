require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Gitaly configuration' do
  let(:default_values) do
    { 'certmanager-issuer' => { 'email' => 'test@example.com' } }
  end

  context 'When disabled and provided external instances' do
    let(:values) do
      {
        'global' => {
          'gitaly' => {
            'enabled' => false,
            'external' => [
              {
                'name' => 'default',
                'hostname' => 'git.example.com',
              }
            ],
          },
        }
      }.deep_merge(default_values)
    end

    it 'populates external instances to gitlab.yml' do
      t = HelmTemplate.new(values)
      expect(t.exit_code).to eq(0)
      # check that gitlab.yml.erb contains production.repositories.storages
      gitlab_yml = t.dig('ConfigMap/test-webservice','data','gitlab.yml.erb')
      storages = YAML.load(gitlab_yml)['production']['repositories']['storages']
      expect(storages).to have_key('default')
      expect(storages['default']['gitaly_address']).to eq('tcp://git.example.com:8075')
    end

    context 'when external is configured with tlsEnabled' do
      let(:values) do
        {
          'global' => {
            'gitaly' => {
              'enabled' => false,
              'external' => [
                {
                  'name' => 'default',
                  'hostname' => 'git.example.com',
                  'tlsEnabled' => true
                }
              ],
            },
          }
        }.deep_merge(default_values)
      end

      it 'populates a tls uri' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0)
        # check that gitlab.yml.erb contains production.repositories.storages
        gitlab_yml = t.dig('ConfigMap/test-webservice','data','gitlab.yml.erb')
        storages = YAML.load(gitlab_yml)['production']['repositories']['storages']
        expect(storages).to have_key('default')
        expect(storages['default']['gitaly_address']).to eq('tls://git.example.com:8076')
      end
    end

    context 'when tls is enabled' do
      let(:values) do
        {
          'global' => {
            'gitaly' => {
              'enabled' => false,
              'external' => [
                {
                  'name' => 'default',
                  'hostname' => 'git.example.com',
                },
              ],
              'tls' => { 'enabled' => true }
            },
          }
        }.deep_merge(default_values)
      end

      it 'populates a tls uri' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0)
        # check that gitlab.yml.erb contains production.repositories.storages
        gitlab_yml = t.dig('ConfigMap/test-webservice','data','gitlab.yml.erb')
        storages = YAML.load(gitlab_yml)['production']['repositories']['storages']
        expect(storages).to have_key('default')
        expect(storages['default']['gitaly_address']).to eq('tls://git.example.com:8076')
      end
    end

    context 'when tls is enabled, and instance disables tls' do
      let(:values) do
        {
          'global' => {
            'gitaly' => {
              'enabled' => false,
              'external' => [
                {
                  'name' => 'default',
                  'hostname' => 'git.example.com',
                  'tlsEnabled' => false
                },
              ],
              'tls' => { 'enabled' => true }
            },
          }
        }.deep_merge(default_values)
      end

      it 'populates a tcp uri' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0)
        # check that gitlab.yml.erb contains production.repositories.storages
        gitlab_yml = t.dig('ConfigMap/test-webservice','data','gitlab.yml.erb')
        storages = YAML.load(gitlab_yml)['production']['repositories']['storages']
        expect(storages).to have_key('default')
        expect(storages['default']['gitaly_address']).to eq('tcp://git.example.com:8075')
      end
    end
  end

  context 'when rendering gitaly securityContexts' do
    context 'when the administrator changes or deletes values' do
      using RSpec::Parameterized::TableSyntax
      where(:fsGroup, :runAsUser, :expectedContext) do
        nil | nil | { 'fsGroup' => 1000, 'runAsUser' => 1000 }
        nil | ""  | { 'fsGroup' => 1000 }
        nil | 24  | { 'fsGroup' => 1000, 'runAsUser' => 24 }
        42  | nil | { 'fsGroup' => 42, 'runAsUser' => 1000 }
        42  | ""  | { 'fsGroup' => 42 }
        42  | 24  | { 'fsGroup' => 42, 'runAsUser' => 24 }
        ""  | nil | { 'runAsUser' => 1000 }
        ""  | ""  | nil
        ""  | 24  | { 'runAsUser' => 24 }
      end

      with_them do
        let(:values) do
          {
            'gitlab' => {
              'gitaly' => {
                'securityContext' => {
                  'fsGroup' => fsGroup,
                  'runAsUser' => runAsUser
                }.select { |k, v| !v.nil? }
              }
            }
          }.deep_merge(default_values)
        end
        let(:gitaly_stateful_set) { 'StatefulSet/test-gitaly' }

        it 'should render securityContext correctly' do
          t = HelmTemplate.new(values)
          gitaly_set = t.resources_by_kind('StatefulSet').select { |key| key == gitaly_stateful_set }
          security_context = gitaly_set[gitaly_stateful_set]['spec']['template']['spec']['securityContext']

          expect(security_context).to eq(expectedContext)
        end
      end
    end
  end

  context 'When customer provides additional labels' do
    let(:labeled_values) do
      {
        'global' => {
          'common' => {
            'labels' => {
              'global' => 'global',
              'foo' => 'global'
            }
          },
          'operator' => {
            'enabled' => true
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
          'gitaly' => {
            'common' => {
              'labels' => {
                'global' => 'gitaly',
                'gitaly' => 'gitaly'
              }
            },
            'podLabels' => {
              'pod' => true,
              'global' => 'pod'
            },
            'serviceAccount' => {
              'create' => true,
              'enabled' => true
            },
            'serviceLabels' => {
              'service' => true,
              'global' => 'service'
            }
          }
        }
      }.deep_merge(default_values)
    end

    context 'with only gitaly' do
      it 'Populates the additional labels in the expected manner' do
        t = HelmTemplate.new(labeled_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        expect(t.dig('ConfigMap/test-gitaly', 'metadata', 'labels')).to include('global' => 'gitaly')
        expect(t.dig('StatefulSet/test-gitaly', 'metadata', 'labels')).to include('foo' => 'global')
        expect(t.dig('StatefulSet/test-gitaly', 'metadata', 'labels')).to include('global' => 'gitaly')
        expect(t.dig('StatefulSet/test-gitaly', 'metadata', 'labels')).not_to include('global' => 'global')
        expect(t.dig('StatefulSet/test-gitaly', 'spec', 'template', 'metadata', 'labels')).to include('global' => 'pod')
        expect(t.dig('StatefulSet/test-gitaly', 'spec', 'template', 'metadata', 'labels')).to include('pod' => true)
        expect(t.dig('StatefulSet/test-gitaly', 'spec', 'template', 'metadata', 'labels')).to include('global_pod' => true)
        expect(t.dig('PodDisruptionBudget/test-gitaly', 'metadata', 'labels')).to include('global' => 'gitaly')
        expect(t.dig('Service/test-gitaly', 'metadata', 'labels')).to include('global' => 'service')
        expect(t.dig('Service/test-gitaly', 'metadata', 'labels')).to include('gitaly' => 'gitaly')
        expect(t.dig('Service/test-gitaly', 'metadata', 'labels')).to include('global_service' => true)
        expect(t.dig('Service/test-gitaly', 'metadata', 'labels')).to include('service' => true)
        expect(t.dig('Service/test-gitaly', 'metadata', 'labels')).not_to include('global' => 'global')
        expect(t.dig('ServiceAccount/test-gitaly', 'metadata', 'labels')).to include('global' => 'gitaly')
        expect(t.dig('ServiceAccount/test-gitaly-pause', 'metadata', 'labels')).to include('global' => 'gitaly')
        expect(t.dig('Role/test-gitaly-pause', 'metadata', 'labels')).to include('global' => 'gitaly')
        expect(t.dig('RoleBinding/test-gitaly-pause', 'metadata', 'labels')).to include('global' => 'gitaly')
        expect(t.dig('Job/test-gitaly-pause', 'metadata', 'labels')).to include('global' => 'gitaly')
      end
    end

    context 'with praefect enabled' do
      let(:praefect_labeled_values) do
        {
          'global' => {
            'praefect' => {
              'enabled' => true,
              'virtualStorages' => [{
                'name' => 'foo'
              }]
            }
          }
        }.deep_merge(default_values).deep_merge(labeled_values)
      end

      it 'Populates the additional labels in the expected manner' do
        t = HelmTemplate.new(praefect_labeled_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        expect(t.dig('ConfigMap/test-gitaly', 'metadata', 'labels')).to include('global' => 'gitaly')
        expect(t.dig('StatefulSet/test-gitaly-foo', 'metadata', 'labels')).to include('foo' => 'global')
        expect(t.dig('StatefulSet/test-gitaly-foo', 'metadata', 'labels')).to include('global' => 'gitaly')
        expect(t.dig('StatefulSet/test-gitaly-foo', 'metadata', 'labels')).not_to include('global' => 'global')
        expect(t.dig('StatefulSet/test-gitaly-foo', 'spec', 'template', 'metadata', 'labels')).to include('global' => 'pod')
        expect(t.dig('StatefulSet/test-gitaly-foo', 'spec', 'template', 'metadata', 'labels')).to include('pod' => true)
        expect(t.dig('StatefulSet/test-gitaly-foo', 'spec', 'template', 'metadata', 'labels')).to include('global_pod' => true)
        expect(t.dig('PodDisruptionBudget/test-gitaly-foo', 'metadata', 'labels')).to include('global' => 'gitaly')
        expect(t.dig('Service/test-gitaly-foo', 'metadata', 'labels')).to include('gitaly' => 'gitaly')
        expect(t.dig('Service/test-gitaly-foo', 'metadata', 'labels')).to include('global' => 'service')
        expect(t.dig('Service/test-gitaly-foo', 'metadata', 'labels')).to include('global_service' => true)
        expect(t.dig('Service/test-gitaly-foo', 'metadata', 'labels')).to include('service' => true)
        expect(t.dig('Service/test-gitaly-foo', 'metadata', 'labels')).not_to include('global' => 'global')
        expect(t.dig('ServiceAccount/test-gitaly', 'metadata', 'labels')).to include('global' => 'gitaly')
      end
    end
  end
end
