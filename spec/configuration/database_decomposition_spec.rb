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
  
  describe 'No decomposition' do
    context 'default configuration' do
      it '`database.yml` Provides only `main` stanza and uses in-chart postgresql service' do
        t = HelmTemplate.new(default_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        db_config = database_config(t,'webservice')
        expect(db_config['production'].keys).to contain_exactly('main')
        expect(db_config['production'].dig('main','host')).to eq('test-postgresql.default.svc')
      end
    end

    context '`main` is provided' do
      it 'inherits settings from x.psql where not provided, uses own' do
        t = HelmTemplate.new(default_values.deep_merge(YAML.safe_load(%(
          global:
            psql:
              password:
                secret: sekrit
                key: pa55word
              main:
                host: server
                port: 9999
        ))))

        db_config = database_config(t,'webservice')
        expect(db_config['production'].dig('main','host')).to eq('server')
        expect(db_config['production'].dig('main','port')).to eq(9999)
        
        webservice_secret_mounts =  t.projected_volume_sources('Deployment/test-webservice-default','init-webservice-secrets').select { |item|
          item['secret']['name'] == 'sekrit' && item['secret']['items'][0]['key'] == 'pa55word'
        }
        expect(webservice_secret_mounts.length).to eq(1)
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

    context 'volumes' do
      it 'Does not template password files for `bogus` stanza' do
        t = HelmTemplate.new(decompose_bogus)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        webservice_secret_mounts =  t.projected_volume_sources('Deployment/test-webservice-default','init-webservice-secrets').select { |item|
          item['secret']['items'][0]['key'] == 'postgresql-password' && item['secret']['items'][0]['path'] == 'postgres/psql-password-bogus'
        }
        expect(webservice_secret_mounts.length).to eq(0)
      end
    end
  end
  
  describe 'CI is decomposed (x.psql.ci)' do
    let(:decompose_ci) do
      default_values.deep_merge(YAML.safe_load(%(
        global:
          psql:
            ci:
              foo: bar
      )))
    end

    context 'minimal configuration' do
      it 'Provides `main` and `ci` stanzas' do
        t = HelmTemplate.new(decompose_ci)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        db_config = database_config(t,'webservice')
        expect(db_config['production'].keys).to include('main','ci')
        expect(db_config['production'].dig('main','host')).to eq('test-postgresql.default.svc')
        expect(db_config['production'].dig('ci','host')).to eq('test-postgresql.default.svc')
      end

      it 'Templates different password files for each stanza' do
        t = HelmTemplate.new(decompose_ci)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        database_yml = database_yml(t,'webservice')
        expect(database_yml).to include('/etc/gitlab/postgres/psql-password-main','/etc/gitlab/postgres/psql-password-ci')
      end
    end
  end
end
