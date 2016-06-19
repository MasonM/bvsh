require 'spec_helper'

describe Avsh::ParsedConfig do
  context 'with /vagrant mapped to a non-default directory' do
    subject { described_class.new({ '/foo/bar' => '.' }, {}, nil) }

    it 'returns the mapped directory in collect_folders_by_machine' do
      expect(subject.collect_folders_by_machine).to eq(
        'default' => { '/foo/bar' => '.' }
      )
    end
  end

  context 'with single machine' do
    subject { described_class.new({}, {}, nil) }

    it 'returns false in machine?' do
      expect(subject.machine?('foo')).to be false
    end

    it 'returns \'default\' in first_machine' do
      expect(subject.first_machine).to eq 'default'
    end

    it 'returns nil in primary_machine' do
      expect(subject.primary_machine).to be nil
    end

    it 'returns default vagrant share in collect_folders_by_machine' do
      expect(subject.collect_folders_by_machine).to eq(
        'default' => { '/vagrant' => '.' }
      )
    end
  end

  context 'with disabled folders' do
    subject do
      described_class.new(
        { '/foo/' => '/default' },
        {
          'main' => {
            '/foo/' => { host_path: '/default', disabled: true },
            '/vagrant' => { host_path: '.', disabled: true },
            '/bar/' => { host_path: '/baz' }
          }
        },
        nil
      )
    end

    it 'only returns the /bar/ => /baz/ folder in collect_folders_by_machine' do
      expect(subject.collect_folders_by_machine).to eq(
        'main' => { '/bar/' => '/baz' }
      )
    end
  end

  context 'with multiple machines' do
    subject do
      described_class.new(
        { '/foo/' => '/default' },
        {
          'first' => { '/bar' => { host_path: '/foo' } },
          'primary' => {},
          'overrides_defaults' => {
            '/vagrant2' => { host_path: '.' },
            '/foo/' => { host_path: '/new' }
          }
        },
        'primary'
      )
    end

    it 'returns false in machine? when given non-existent machine' do
      expect(subject.machine?('foo')).to be false
    end

    it 'returns true in machine? when given valid machine' do
      expect(subject.machine?('overrides_defaults')).to be true
    end

    it 'returns name of first machine in first_machine' do
      expect(subject.first_machine).to eq 'first'
    end

    it 'returns name of primary machine in primary_machien' do
      expect(subject.primary_machine).to eq 'primary'
    end

    it 'returns synced folder mappings in collect_folders_by_machine' do
      # call to_a on the hash because we want to ensure 'primary' is ordered to
      # the top, and the normal hash comparisons don't respect order
      expect(subject.collect_folders_by_machine.to_a).to eq [
        ['primary', {
          '/foo/' => '/default',
          '/vagrant' => '.'
        }],
        ['first', {
          '/foo/' => '/default',
          '/vagrant' => '.',
          '/bar' => '/foo'
        }],
        ['overrides_defaults', {
          '/foo/' => '/new',
          '/vagrant2' => '.'
        }]
      ]
    end
  end
end
