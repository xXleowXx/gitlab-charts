require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'gitlab-shell configuration' do
  let(:t) { HelmTemplate.new(values) }
  let(:default_values) do
    YAML.safe_load(%(
      certmanager-issuer:
        email: test@example.com
      global: {}
      gitlab:
        gitlab-shell:
          networkpolicy:
            enabled: true
          serviceAccount:
            enabled: true
            create: true
    ))
  end

  def expect_successful_exit_code
    expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
  end

  context 'when gitlab-sshd is enabled' do
    let(:proxy_protocol) { true }
    let(:values) do
      YAML.safe_load(%(
        gitlab:
          gitlab-shell:
            sshDaemon: "gitlab-sshd"
            config:
              proxyProtocol: #{proxy_protocol}
      )).deep_merge(default_values)
    end

    shared_examples 'gitlab-sshd config' do
      let(:config) { t.dig('ConfigMap/test-gitlab-shell', 'data', 'config.yml.tpl') }

      it 'renders gitlab-sshd config' do
        expect_successful_exit_code
        expect(config).to match(/^sshd:$/)
        expect(config).to include("proxy_protocol: #{proxy_protocol}")
      end
    end

    it_behaves_like 'gitlab-sshd config'

    context 'when proxyProtocol is disabled' do
      let(:proxy_protocol) { false }

      it_behaves_like 'gitlab-sshd config'
    end
  end

  context 'when PROXY protocol is set' do
    using RSpec::Parameterized::TableSyntax

    where(:in_proxy_protocol, :out_proxy_protocol, :expected_suffix) do
      false | false | ""
      true  | false | ":PROXY"
      true  | true  | ":PROXY:PROXY"
      false | true  | "::PROXY"
    end

    with_them do
      let(:values) do
        YAML.safe_load(%(
          global:
            shell:
              tcp:
                proxyProtocol: #{in_proxy_protocol}
          gitlab:
            gitlab-shell:
              config:
                proxyProtocol: #{out_proxy_protocol}
        )).deep_merge(default_values)
      end

      it 'should render NGINX ingress TCP data correctly' do
        expect_successful_exit_code

        data = t.dig('ConfigMap/test-nginx-ingress-tcp', 'data')

        expect(data.keys).to eq(['22'])
        expect(data['22']).to eq("default/test-gitlab-shell:22#{expected_suffix}")
      end
    end
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
          service:
            labels:
              global_service: true
        gitlab:
          gitlab-shell:
            common:
              labels:
                global: shell
                shell: shell
            podLabels:
              pod: true
              global: pod
            serviceLabels:
              service: true
              global: service
      )).deep_merge(default_values)
    end

    it 'Populates the additional labels in the expected manner' do
      expect_successful_exit_code

      expect(t.dig('ConfigMap/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'shell')
      expect(t.dig('Deployment/test-gitlab-shell', 'metadata', 'labels')).to include('foo' => 'global')
      expect(t.dig('Deployment/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'shell')
      expect(t.dig('Deployment/test-gitlab-shell', 'metadata', 'labels')).not_to include('global' => 'global')
      expect(t.dig('Deployment/test-gitlab-shell', 'spec', 'template', 'metadata', 'labels')).to include('global' => 'pod')
      expect(t.dig('Deployment/test-gitlab-shell', 'spec', 'template', 'metadata', 'labels')).to include('pod' => 'true')
      expect(t.dig('Deployment/test-gitlab-shell', 'spec', 'template', 'metadata', 'labels')).to include('global_pod' => 'true')
      expect(t.dig('HorizontalPodAutoscaler/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'shell')
      expect(t.dig('NetworkPolicy/test-gitlab-shell-v1', 'metadata', 'labels')).to include('global' => 'shell')
      expect(t.dig('PodDisruptionBudget/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'shell')
      expect(t.dig('Service/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'service')
      expect(t.dig('Service/test-gitlab-shell', 'metadata', 'labels')).to include('global_service' => 'true')
      expect(t.dig('Service/test-gitlab-shell', 'metadata', 'labels')).to include('service' => 'true')
      expect(t.dig('Service/test-gitlab-shell', 'metadata', 'labels')).not_to include('global' => 'global')
      expect(t.dig('ServiceAccount/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'shell')
    end
  end
end
