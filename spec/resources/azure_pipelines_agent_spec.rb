require 'spec_helper'

describe 'installing azure pipelines agent with the default action on ubuntu' do
  step_into :azure_pipelines_agent
  platform 'ubuntu'

  default_attributes['azure_pipelines_agent']['binary']['version'] = '2.170.1'
  default_attributes['azure_pipelines_agent']['binary']['url'] = 'https://vstsagentpackage.azureedge.net/agent/%s/vsts-agent-linux-x64-%s.tar.gz'

  context 'with the default action' do
    recipe do
      azure_pipelines_agent 'node1' do
        install_dir '/home/plumber/.azure/pipelines/agent'
      end
    end

    it { is_expected.to create_directory('/home/plumber/.azure/pipelines/agent') }
  end
end
