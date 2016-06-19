require 'spec_helper'

describe 'VagrantfileEvaluator integration tests' do
  before do
    skip('cloning the VagrantfileEnvironment doesn\'t work under ' \
         'Ruby 1.9.3') if RUBY_VERSION == '1.9.3'
  end

  subject do
    Avsh::VagrantfileEvaluator.new(double(debug: nil),
                                   Avsh::VagrantfileEnvironment.clone)
  end

  let(:vagrantfiles_dir) { File.dirname(__FILE__) + '/vagrantfiles' }

  context 'with Vagrant\'s Vagrantfile' do
    let!(:parsed_config) { subject.evaluate("#{vagrantfiles_dir}/vagrant") }

    it 'has a single unnamed machine' do
      expect(parsed_config.first_machine).to eq 'default'
    end

    it 'only has the default synced folder' do
      expect(parsed_config.collect_folders_by_machine).to eq(
        'default' => { '/vagrant' => vagrantfiles_dir }
      )
    end
  end

  context 'with History of Science Society\'s Vagrantfile' do
    let!(:parsed_config) do
      subject.evaluate("#{vagrantfiles_dir}/history_of_science_society")
    end

    it 'has a single machine named "hss"' do
      expect(parsed_config.first_machine).to eq 'hss'
      expect(parsed_config.machine?('hss')).to be true
    end

    it 'has the default synced folder and one defined synced folder' do
      expect(parsed_config.collect_folders_by_machine).to eq(
        'hss' => {
          '/vagrant' => vagrantfiles_dir,
          '/home/vagrant/hss' => File.dirname(__FILE__)
        }
      )
    end
  end

  context 'with Vagrant Google Compute Engine\'s Vagrantfile' do
    let!(:parsed_config) do
      subject.evaluate("#{vagrantfiles_dir}/vagrant_google")
    end

    it 'has two machines, z1c and z1f' do
      expect(parsed_config.first_machine).to eq 'z1c'
      expect(parsed_config.machine?('z1c')).to be true
      expect(parsed_config.machine?('z1f')).to be true
    end

    it 'has the default synced folder for both machines' do
      expect(parsed_config.collect_folders_by_machine).to eq(
        'z1c' => { '/vagrant' => vagrantfiles_dir },
        'z1f' => { '/vagrant' => vagrantfiles_dir }
      )
    end
  end

  context 'with Vagrant LAMP Stack\'s Vagrantfile' do
    let!(:parsed_config) do
      subject.evaluate("#{vagrantfiles_dir}/vagrant_lamp_stack")
    end

    it 'has a single machine, "projectname"' do
      expect(parsed_config.first_machine).to eq 'projectname'
    end

    it 'overides the default synced folder for the machine' do
      expect(parsed_config.collect_folders_by_machine).to eq(
        'projectname' => { '/var/www/projectname' => vagrantfiles_dir }
      )
    end
  end
end
