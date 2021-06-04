require 'spec_helper'
require 'tempfile'
require 'tmpdir'
require 'tasks'
require_relative '../task_spec_helper'
require_relative '../../../concourse/tasks/resolve_manifest_versions/resolve_manifest_urls'

describe PrecompileOfflineReleaseUrlResolver do
  subject(:release_url_resolver) { described_class.new(config) }

  describe '#accept?' do
    let(:accept) { release_url_resolver.accept? }

    context 'when offline mode and precompile mode are enabled' do
      let(:config) { { 'OFFLINE_MODE_ENABLED' => true, 'PRECOMPILE_MODE_ENABLED' => true } }

      it 'accepts to process request' do
        expect(accept).to be true
      end
    end

    context 'when offline mode is enable and precompile mode is not' do
      let(:config) { { 'OFFLINE_MODE_ENABLED' => true, 'PRECOMPILE_MODE_ENABLED' => false } }

      it 'refuses to process request' do
        expect(accept).to be false
      end
    end

    context 'when offline mode and precompile mode are disabled' do
      let(:config) { { 'OFFLINE_MODE_ENABLED' => false, 'PRECOMPILE_MODE_ENABLED' => false } }

      it 'refuses to process request' do
        expect(accept).to be false
      end
    end

    context 'when offline mode is disable and precompile mode is not' do
      let(:config) { { 'OFFLINE_MODE_ENABLED' => false, 'PRECOMPILE_MODE_ENABLED' => true } }

      it 'refuses to process request' do
        expect(accept).to be false
      end
    end
  end

  describe '#resolve' do
    let(:resolve) { release_url_resolver.resolve(release_name, release_version, release_repository) }
    let(:release_name) { 'minio' }
    let(:release_version) { '2.0' }
    let(:release_repository) { 'minio-org/minio-boshrelease' }
    let(:config) do
      {
        'DOWNLOAD_SERVER_URL' => 'https://private-s3.internal.paas/compiled-releases/',
        'OFFLINE_MODE_ENABLED' => true,
        'PRECOMPILE_MODE_ENABLED' => true,
        'STEMCELL_NAME' => 'my-stemcell',
        'STEMCELL_OS' => 'my-os',
        'STEMCELL_VERSION' => '0.0.7'
      }
    end

    context 'when valid' do
      let(:expected) do
        {
          'url' => "https://private-s3.internal.paas/compiled-releases/minio-org/minio-2.0-my-os-0.0.7.tgz",
          'exported_from' => [{ 'os' => 'my-os', 'version' => '0.0.7' }],
          'sha1' => '',
          'stemcell' => { 'os' => 'my-os', 'version' => '0.0.7' }
        }
      end

      it 'generates updated data' do
        expect(resolve).to match(expected)
      end
    end

    context 'when config is empty ' do
      let(:config) { {} }
      let(:expected) { {} }

      it 'generates updated data' do
        expect(resolve).to match(expected)
      end
    end
  end
end

describe OfflineReleaseUrlResolver do
  subject(:release_url_resolver) { described_class.new(config) }

  let(:config) do
    {
        'STEMCELL_NAME' => 'my-stemcell',
        'STEMCELL_OS' => 'my-os',
        'STEMCELL_VERSION' => '0.0.7'
    }
  end

  describe '#accept?' do
    let(:accept) { release_url_resolver.accept? }

    context 'when offline mode and precompile mode are enabled' do
      let(:config) { { 'OFFLINE_MODE_ENABLED' => true, 'PRECOMPILE_MODE_ENABLED' => true } }

      it 'refuses to process request' do
        expect(accept).to be false
      end
    end

    context 'when offline mode is enable and precompile mode is not' do
      let(:config) { { 'OFFLINE_MODE_ENABLED' => true, 'PRECOMPILE_MODE_ENABLED' => false } }

      it 'accepts to process request' do
        expect(accept).to be true
      end
    end

    context 'when offline mode and precompile mode are disabled' do
      let(:config) { { 'OFFLINE_MODE_ENABLED' => false, 'PRECOMPILE_MODE_ENABLED' => false } }

      it 'refuses to process request' do
        expect(accept).to be false
      end
    end

    context 'when offline mode is disable and precompile mode is not' do
      let(:config) { { 'OFFLINE_MODE_ENABLED' => false, 'PRECOMPILE_MODE_ENABLED' => true } }

      it 'refuses to process request' do
        expect(accept).to be false
      end
    end
  end

  describe '#resolve' do
    let(:resolve) { release_url_resolver.resolve(release_name, release_version, release_repository) }
    let(:release_name) { 'minio' }
    let(:release_version) { '2.0' }
    let(:release_repository) { 'minio-org/minio-boshrelease' }
    let(:config) do
      {
          'DOWNLOAD_SERVER_URL' => 'https://private-s3.internal.paas/releases/',
          'OFFLINE_MODE_ENABLED' => true,
          'PRECOMPILE_MODE_ENABLED' => false
      }
    end

    context 'when valid ' do
      let(:expected) do
        {
            'url' => "https://private-s3.internal.paas/releases/minio-org/minio-2.0.tgz",
            'sha1' => ''
        }
      end

      it 'generates updated data' do
        expect(resolve).to match(expected)
      end
    end

    context 'when config is empty ' do
      let(:config) { {} }
      let(:expected) { {} }

      it 'generates updated data' do
        expect(resolve).to match(expected)
      end
    end
  end
end


describe BoshIoReleaseUrlResolver do
  subject(:release_url_resolver) { described_class.new(config) }

  let(:config) do
    {
        'STEMCELL_NAME' => 'my-stemcell',
        'STEMCELL_OS' => 'my-os',
        'STEMCELL_VERSION' => '0.0.7'
    }
  end

  describe '#accept?' do
    let(:accept) { release_url_resolver.accept? }

    context 'when offline mode is enable, so online mode is disable' do
      let(:config) { { 'OFFLINE_MODE_ENABLED' => true } }

      it 'refuses to process request' do
        expect(accept).to be false
      end
    end

    context 'when offline mode is disable, so online mode is enable' do
      let(:config) { { 'OFFLINE_MODE_ENABLED' => false } }

      it 'accepts to process request' do
        expect(accept).to be true
      end
    end
  end

  describe '#resolve' do
    let(:resolve) { release_url_resolver.resolve(release_name, release_version, release_repository) }
    let(:release_name) { 'minio' }
    let(:release_version) { '2.0' }
    let(:release_repository) { 'minio-org/minio-boshrelease' }
    let(:config) do
      {
        'DOWNLOAD_SERVER_URL' => 'https://bosh.io/releases/',
        'OFFLINE_MODE_ENABLED' => false
      }
    end

    context 'when valid ' do
      let(:expected) do
        {
          'url' => "https://bosh.io/releases/minio-org/minio-boshrelease?v=2.0"
        }
      end

      it 'generates updated data' do
        expect(resolve).to match(expected)
      end
    end

    context 'when config is empty ' do
      let(:config) { {} }
      let(:expected) { {} }

      it 'generates updated data' do
        expect(resolve).to match(expected)
      end
    end
  end
end

describe ResolveManifestReleaseUrlFactory do
  subject(:url_factory) { described_class.new(resolver) }

  let(:resolver) { [] }

  describe '#select_resolver' do
    context 'when no resolver are provided' do
      it 'raises an error' do
        expect { url_factory.select_resolver }.to raise_error(RuntimeError, 'Cannot find suitable resolver, please check Environment Variables')
      end
    end

    context 'when online mode is activated' do
      subject(:select_resolver) { factory.select_resolver }

      let(:factory) { described_class.factory(config) }
      let(:config) { { 'OFFLINE_MODE_ENABLED' => 'false', 'PRECOMPILE_MODE_ENABLED' => 'true' } }

      it 'returns a Bosh IO resolver' do
        expect(select_resolver).to be_kind_of(BoshIoReleaseUrlResolver)
      end
    end

    context 'when precomplile offline mode is activated' do
      subject(:select_resolver) { factory.select_resolver }

      let(:factory) { described_class.factory(config) }
      let(:config) { { 'OFFLINE_MODE_ENABLED' => 'true', 'PRECOMPILE_MODE_ENABLED' => 'true' } }

      it 'returns a compiled releases resolver' do
        expect(select_resolver).to be_kind_of(PrecompileOfflineReleaseUrlResolver)
      end
    end

    context 'when offline compiled mode is activated' do
      subject(:select_resolver) { factory.select_resolver }

      let(:factory) { described_class.factory(config) }
      let(:config) { { 'OFFLINE_MODE_ENABLED' => 'true', 'PRECOMPILE_MODE_ENABLED' => 'false' } }

      it 'returns a offline releases resolver' do
        expect(select_resolver).to be_kind_of(OfflineReleaseUrlResolver)
      end
    end
  end

  describe '#self.factory' do
    subject(:factory) { described_class.factory(config) }

    let(:config) { {} }
    let(:list_resolver) { factory.list_resolver }

    context 'when called' do
      it 'creates a factory with default resolvers' do
        # expect(list_resolver).to match([be_kind_of(CompiledOfflineReleaseUrlResolver), be_kind_of(OfflineReleaseUrlResolver), be_kind_of(BoshIoReleaseUrlResolver)])
        expect(list_resolver).to include(be_kind_of(BoshIoReleaseUrlResolver)).and include(be_kind_of(OfflineReleaseUrlResolver)).and include(be_kind_of(PrecompileOfflineReleaseUrlResolver))
      end
    end
  end
end
