require 'spec_helper'
require 'check_config_helper'
require 'hash_deep_merge'

describe 'checkConfig toolbox' do
  describe 'gitaly.toolbox.replicas' do
    let(:success_values) do
      YAML.safe_load(%(
        gitlab:
          toolbox:
            replicas: 1
            persistence:
              enabled: true
      )).merge(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        gitlab:
          toolbox:
            replicas: 2
            persistence:
              enabled: true
      )).merge(default_required_values)
    end

    let(:error_output) { 'more than 1 replica, but also with a PersistentVolumeClaim' }

    include_examples 'config validation',
                     success_description: 'when toolbox has persistence enabled and one replica',
                     error_description: 'when toolbox has persistence enabled and more than one replica'
  end

  describe 'gitlab.toolbox.backups.objectStorage.config.secret' do
    describe 'gitlab.toolbox.enabled (the default value)' do
      let(:success_values) do
        YAML.safe_load(%(
          gitlab:
            toolbox:
              enabled: true
              backups:
                objectStorage:
                  config:
                    secret: s3cmd-config
                    key: config
        )).merge(default_required_values)
      end

      let(:error_values) do
        YAML.safe_load(%(
          gitlab:
            toolbox:
              enabled: true
              backups:
                objectStorage:
                  config:
                    # secret: s3cmd-config
                    key: config
        )).merge(default_required_values)
      end

      let(:error_output) { 'A valid object storage config secret is needed for backups.' }

      include_examples 'config validation',
                       success_description: 'when toolbox has a valid object storage backup secret configured',
                       error_description: 'when toolbox does not have a valid object storage backup secret configured'
    end

    describe 'gitlab.toolbox.enabled (set to false)' do
      let(:success_values) do
        YAML.safe_load(%(
          gitlab:
            toolbox:
              enabled: false
              backups:
                objectStorage:
                  config:
                    # secret: s3cmd-config
                    key: config
        )).merge(default_required_values)
      end

      include_examples 'config validation',
                       success_description: 'when toolbox is disabled and does not have a valid object storage backup secret configured'
    end

    describe 'is using Azure as backup backend' do
      let(:success_values) do
        YAML.safe_load(%(
          gitlab:
            toolbox:
              enabled: true
              backups:
                objectStorage:
                  config:
                    secret: s3cmd-config
                    key: config
                  azureBaseUrl: "https://mystorage.blob.core.windows.net"
        )).merge(default_required_values)
      end

      let(:error_values) do
        YAML.safe_load(%(
          gitlab:
            toolbox:
              enabled: true
              backups:
                objectStorage:
                  config:
                    secret: s3cmd-config
                    key: config
                  backend: azure
                  # azureBaseUrl: "https://mystorage.blob.core.windows.net"
        )).merge(default_required_values)

        let(:error_output) { 'A valid Azure base URL is needed for backing up to Azure.' }

        include_examples 'config validation',
                         success_description: 'when toolbox is using Azure backend with base URL configured',
                         error_description: 'when toolbox is using Azure backend without base URL confiured'
      end
    end
  end
end
