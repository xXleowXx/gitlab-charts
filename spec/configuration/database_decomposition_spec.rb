require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Database configuration' do
  def database_yml(template,chart_name)
    template.dig("ConfigMap/test-#{chart_name}",'data','database.yml.erb')
  end

  def database_config(template,chart_name)
    db_config = database_yml(template, chart_name)
    YAML.safe_load(db_config)
  end 

  let(:default_values) do
    HelmTemplate.certmanager_issuer.deep_merge(YAML.safe_load(%(
      global:
        psql:
          host: ''
          serviceName: ''
          username: ''
          database: ''
          applicationName: nil
          preparedStatements: ''
          password:
            secret: ''
            key: ''
          load_balancing: {}
          connectTimeout: nil
          keepalives: nil
          keepalivesIdle: nil
          keepalivesInterval: nil
          keepalivesCount: nil
          tcpUserTimeout: nil
      postgresql:
        install: true
    )))
  end

  let(:decompose_ci) do
    default_values.deep_merge(YAML.safe_load(%(
      global:
        psql:
          ci:
            foo: bar
    )))
  end

  
  describe 'No decomposition (defaults)' do
    context 'database.yml' do
      it 'Provides only `main` stanza, using in-chart postgresql service' do
        t = HelmTemplate.new(default_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        db_config = database_config(t,'webservice')
        expect(db_config['production'].keys).to contain_exactly('main')
        expect(db_config['production'].dig('main','host')).to eq('test-postgresql.default.svc')
      end
    end
  end

  describe 'Invalid decomposition (x.psql.bogus)' do
    let(:decompose_bogus) do
      default_values.deep_merge(YAML.safe_load(%(
        global:
          psql:
            bogus:
              host: bogus
      )))
    end

    context 'database.yml' do
      it 'Does not contain `bogus` stanza' do
        t = HelmTemplate.new(decompose_bogus)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        db_config = database_config(t,'webservice')
        expect(db_config['production'].keys).not_to include('bogus')
      end
    end
  end
  
  describe 'CI is decomposed (x.psql.ci)' do
    context 'database.yml' do
      it 'Provides `ci` stanza' do
        t = HelmTemplate.new(decompose_ci)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        db_config = database_config(t,'webservice')
        expect(db_config['production'].keys).to include('main','ci')
        expect(db_config['production'].dig('main','host')).to eq('test-postgresql.default.svc')
        expect(db_config['production'].dig('ci','host')).to eq('test-postgresql.default.svc')
      end
    end
  end
end
