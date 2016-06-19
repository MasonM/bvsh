require 'spec_helper'

describe Avsh::MachineGuestDirMatcher do
  let(:stub_config) { double(Avsh::ParsedConfig) }

  subject do
    described_class.new(double(debug: nil), '/foo/Vagrantfile', stub_config)
  end

  context 'with non-existent desired machine' do
    it 'raises exception' do
      allow(stub_config).to receive(:collect_folders_by_machine)
      allow(stub_config).to receive(:machine?).with('foo').and_return(false)
      expect { subject.match('/', 'foo') }
        .to raise_error(Avsh::MachineNotFoundError)
    end
  end

  context 'with desired machine' do
    context 'without synced folders' do
      it 'uses the desired machine' do
        allow(stub_config).to receive_messages(
          collect_folders_by_machine: {},
          machine?: true
        )
        expect(subject.match('/', 'machine1')).to eq ['machine1', nil]
      end
    end

    context 'no matching synced folders' do
      it 'uses the desired machine' do
        allow(stub_config).to receive_messages(
          collect_folders_by_machine: { machine1: { '/bar' => '/foo' } },
          machine?: true
        )
        expect(subject.match('/', 'machine1')).to eq ['machine1', nil]
      end
    end

    context 'multiple inexact matching synced folders' do
      it 'uses the desired machine and first matching guest dir' do
        allow(stub_config).to receive_messages(
          collect_folders_by_machine: {
            'machine1' => { '/bar' => '/foo' },
            'machine2' => { '/baz' => '/bam', '/bar2' => '/foo' },
            'machine3' => {}
          },
          machine?: true
        )
        expect(subject.match('/foo/foo2/', 'machine2'))
          .to eq ['machine2', '/bar2/foo2']
      end
    end
  end

  context 'without desired machine' do
    context 'without synced folders' do
      it 'uses the primary machine if it exists' do
        allow(stub_config).to receive_messages(
          collect_folders_by_machine: {},
          primary_machine: 'machine1'
        )
        expect(subject.match('/')).to eq ['machine1', nil]
      end

      it 'uses the first machine if no primary machine exists' do
        allow(stub_config).to receive_messages(
          collect_folders_by_machine: {},
          primary_machine: nil,
          first_machine: 'machine2'
        )
        expect(subject.match('/')).to eq ['machine2', nil]
      end
    end
  end

  context 'exact match for a synced folder' do
    it 'uses the guest dir' do
      allow(stub_config).to receive_messages(
        collect_folders_by_machine: { 'machine1' => { '/baz' => '/bam' } }
      )
      expect(subject.match('/bam/')).to eq ['machine1', '/baz/']
    end
  end

  context 'multiple inexact matching synced folders' do
    it 'uses the first matching machine and guest dir' do
      allow(stub_config).to receive_messages(
        collect_folders_by_machine: {
          'machine1' => { '/baz' => '/bam' },
          'machine2' => { '/baz2' => '/baz', '/bar2' => '/foo' },
          'machine3' => { '/bar' => '/foo' }
        }
      )
      expect(subject.match('/foo/foo2/')).to eq ['machine2', '/bar2/foo2']
    end
  end
end
