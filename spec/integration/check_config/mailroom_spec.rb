require 'spec_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'checkConfig mailroom' do
  describe 'incomingEmail.microsoftGraph' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            incomingEmail:
              enabled: true
              inboxMethod: microsoft_graph
              tenantId: MY-TENANT-ID
              clientId: MY-CLIENT-ID
              clientSecret:
                secret: secret
      )).merge(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            incomingEmail:
              enabled: true
              inboxMethod: microsoft_graph
              clientSecret:
                secret: secret
      )).merge(default_required_values)
    end

    let(:error_output) { 'be sure to specify the tenant ID' }

    include_examples 'config validation',
                     success_description: 'when incomingEmail is configured with Microsoft Graph',
                     error_description: 'when incomingEmail is missing required Microsoft Graph settings'
  end

  describe 'serviceDesk.microsoftGraph' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            incomingEmail:
              enabled: true
              inboxMethod: microsoft_graph
              tenantId: MY-TENANT-ID
              clientId: MY-CLIENT-ID
              clientSecret:
                secret: secret
            serviceDesk:
              enabled: true
              inboxMethod: microsoft_graph
              tenantId: MY-TENANT-ID
              clientId: MY-CLIENT-ID
              clientSecret:
                secret: secret
      )).merge(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            incomingEmail:
              enabled: true
              inboxMethod: microsoft_graph
              tenantId: MY-TENANT-ID
              clientId: MY-CLIENT-ID
              clientSecret:
                secret: secret
            serviceDesk:
              enabled: true
              inboxMethod: microsoft_graph
              clientSecret:
                secret: secret
      )).merge(default_required_values)
    end

    let(:error_output) { 'be sure to specify the tenant ID' }

    include_examples 'config validation',
                     success_description: 'when serviceDesk is configured with Microsoft Graph',
                     error_description: 'when serviceDesk is missing required Microsoft Graph settings'
  end
end
