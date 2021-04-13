require 'simp/repo/helpers/file_fetcher'

RSpec.describe Simp::Repo::Helpers::FileFetcher do
  shared_examples 'a successful file fetcher' do
    it 'returns the correct content' do
      content = Simp::Repo::Helpers::FileFetcher.create(url).fetch
      expect(content).to eq expected_content
    end
  end

  shared_examples 'and the url is a local path' do
    context 'and the url is a local path' do
    let(:url){ expected_content_path }
      include_examples 'a successful file fetcher'
    end
  end

  context 'when url content is plaintext XML' do
    let(:expected_content_path){ File.expand_path('../../../fixtures/repodata/repomd.xml', __dir__) }
    let(:expected_content){ File.read(expected_content_path) }

    include_examples 'and the url is a local path'

    context 'and the url is a website' do
      let(:url){ 'https://www.example.com/repodata/repomd.xml' }
      before(:each){ stub_request(:any, url).to_return(body: expected_content) }
      include_examples 'a successful file fetcher'
    end
  end

  context 'when url content is gzipped' do
    let(:expected_content_path){ File.expand_path( '../../../fixtures/test.txt.gz', __dir__) }
    let(:expected_content){ "Test data\n" }
    let(:expected_content_gzipped){ File.read(expected_content_path) }

    include_examples 'and the url is a local path'

    context 'and the url is a website' do
      let(:url){ 'https://www.example.com/repodata/xxx-modules.yaml.gz' }
      before(:each) do
        stub_request(:any, url).to_return(
          body: expected_content_gzipped,
          headers: { 'Content-Type' => 'application/x-gzip' }
        )
      end
      include_examples 'a successful file fetcher'
    end
  end
end

