require 'simp/repo/helpers/dnf_repo'

RSpec.describe Simp::Repo::Helpers::FileFetcher do
  shared_examples 'a successful file fetcher' do
    it '#fetch_modularity' do
      modularity_data = Simp::Repo::Helpers::DnfRepo.fetch_modularity(repo_url,repo_label)
      expect(modularity_data).to be_a(Simp::Repo::Helpers::ModularityData)
      expect(modularity_data.modules).to be_a(Hash)
      expect(modularity_data.modules.keys).to eq ['389-directory-server', 'avocado', 'cobbler', 'dwm', 'libuv', 'nextcloud', 'nginx', 'nodejs', 'swig', 'zabbix']
    end
  end

  context 'when url content is plaintext XML' do
    let(:fixtures_repomd_path){ File.expand_path('../../../fixtures/repodata/repomd.xml', __dir__) }
    let(:fixtures_myamlgz_filename){ '2805960b35ea823fb4150994d0913aa7933b551a8bba7b84e43ab95b988304d1-modules.yaml.gz' }
    let(:fixtures_myamlgz_path){ File.expand_path( "../../../fixtures/repodata/#{fixtures_myamlgz_filename}", __dir__) }
    let(:fixtures_repo_path){ File.dirname(File.dirname(fixtures_repomd_path)) }

    let(:repomd_content){ File.read(fixtures_repomd_path) }
    let(:repo_label){ 'test' }


    context 'and the url is a website' do
      let(:repo_url){ 'https://www.example.com' }
      before(:each) do
        myamlgz_content = File.read(fixtures_myamlgz_path)
        stub_request(:any, "#{repo_url}/repodata/repomd.xml" ).to_return(body: repomd_content)
        stub_request( :any, "#{repo_url}/repodata/#{fixtures_myamlgz_filename}" ).to_return(
          body: myamlgz_content,
          headers: { 'Content-Type' => 'application/x-gzip' }
        )
      end
      include_examples 'a successful file fetcher'
    end
  end

end
