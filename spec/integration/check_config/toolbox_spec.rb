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

      describe 'with MinIO disabled, backups configured, and consolidated object storage enabled' do
        let(:success_values) do
          YAML.safe_load(%(
            global:
              appConfig:
                object_store:
                  enabled: true
                  connection:
                    secret: gitlab-object-storage
                    key: connection
              gitlab:
                toolbox:
                  enabled: true
                  backups:
                    objectStorage:
                      config:
                        secret: s3cmd-config
                        key: config
              minio:
                enabled: false
          )).merge(default_required_values)
        end

        let(:error_values) do
          YAML.safe_load(%(
            gitlab:
              toolbox:
                backups:
                  objectStorage:
                    config:
                      secret:
            )).deep_merge(success_values)
        end

        let(:error_output) { 'A valid object storage config secret is needed for backups.' }

        include_examples 'config validation',
                         success_description: 'when toolbox has MinIO disabled but no object storage config',
                         error_description: 'when toolbox has MinIO disabled but no valid object storage backup secret'
      end

      describe 'with MinIO disabled, backups not configured, and type-specific object storage enabled' do
        let(:success_values) do
          YAML.safe_load(%(
          global:
            appConfig:
              artifacts:
                connection:
                  secret: gitlab-object-storage
                  key: connection
              lfs:
                connection:
                  secret: gitlab-object-storage
                  key: connection
              packages:
                connection:
                  secret: gitlab-object-storage
                  key: connection
              uploads:
                connection:
                  secret: gitlab-object-storage
                  key: connection
            minio:
              enabled: false
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
          )).deep_merge(success_values)
        end

        let(:error_output) { 'A valid object storage config secret is needed for backups.' }

        include_examples 'config validation',
                         success_description: 'when toolbox has MinIO disabled but no object storage config',
                         error_description: 'when toolbox has MinIO disabled but no valid object storage backup secret'
      end

      context 'with Google Cloud Storage backend' do
        let(:success_values) do
          YAML.safe_load(%(
            gitlab:
              toolbox:
                enabled: true
                backups:
                  objectStorage:
                    backend: gcs
                    config:
                      # secret: s3cmd-config
                      key: config
          )).merge(default_required_values)
        end

        include_examples 'config validation',
                         success_description: 'when toolbox uses GCS for backup with no secret configured'
      end
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
  end
end
