require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'migrations configuration' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      global: {}
      gitlab:
        migrations:
          networkpolicy:
            enabled: true
          serviceAccount:
            enabled: true
            create: true
    ))
  end

  context 'When customer provides additional labels' do
    let(:values) do
      YAML.safe_load(%(
        global:
          common:
            labels:
              global: global
              foo: global
          pod:
            labels:
              global_pod: true
        gitlab:
          migrations:
            common:
              labels:
                global: migrations
                migrations: migrations
            podLabels:
              pod: true
              global: pod
      )).deep_merge(default_values)
    end
    it 'Populates the additional labels in the expected manner' do
      t = HelmTemplate.new(values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      migrations_job = t.resources_by_kind_and_labels("Job", { "app" => "migrations" }).values.first
      expect(t.dig('ConfigMap/test-migrations', 'metadata', 'labels')).to include('global' => 'migrations')
      expect(migrations_job.dig('metadata', 'labels')).to include('foo' => 'global')
      expect(migrations_job.dig('metadata', 'labels')).to include('global' => 'migrations')
      expect(migrations_job.dig('metadata', 'labels')).not_to include('global' => 'global')
      expect(migrations_job.dig('spec', 'template', 'metadata', 'labels')).to include('global' => 'pod')
      expect(migrations_job.dig('spec', 'template', 'metadata', 'labels')).to include('pod' => 'true')
      expect(migrations_job.dig('spec', 'template', 'metadata', 'labels')).to include('global_pod' => 'true')
      expect(t.dig('ServiceAccount/test-migrations', 'metadata', 'labels')).to include('global' => 'migrations')
    end
  end

  context 'When customer provides additional annotations' do
    let(:values) do
      YAML.safe_load(%(
        gitlab:
          migrations:
            annotations:
              foo: bar
              bar: foo
            podAnnotations:
              foo: foo
              baz: baz
      )).deep_merge(default_values)
    end
    it 'Populates the additional annotations in the expected manner' do
      t = HelmTemplate.new(values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      migrations_job = t.resources_by_kind_and_labels("Job", { "app" => "migrations" }).values.first
      expect(migrations_job.dig('metadata', 'annotations')).to include('foo' => 'bar')
      expect(migrations_job.dig('metadata', 'annotations')).to include('bar' => 'foo')
      expect(migrations_job.dig('metadata', 'annotations')).not_to include('baz' => 'baz')
      expect(migrations_job.dig('spec', 'template', 'metadata', 'annotations')).to include('foo' => 'foo')
      expect(migrations_job.dig('spec', 'template', 'metadata', 'annotations')).to include('bar' => 'foo')
      expect(migrations_job.dig('spec', 'template', 'metadata', 'annotations')).to include('baz' => 'baz')
    end
  end
end
