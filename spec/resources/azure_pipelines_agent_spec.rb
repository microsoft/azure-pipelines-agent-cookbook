require 'spec_helper'

describe 'installing azure pipelines agent with the default action' do
  step_into :azure_pipelines_agent
  platform 'ubuntu'
  context 'with the default action' do
    recipe do
      azure_pipelines_agent 'node1' do
        install_dir '/home/plumber/.azure/pipelines/agent'
      end
    end

    it { is_expected.to create_directory('/home/plumber/.azure/pipelines/agent') }
  end
end
