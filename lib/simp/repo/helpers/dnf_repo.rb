module Simp
  module Repo
    module Helpers
      class DnfRepo
        require_relative 'file_fetcher'
        require 'rexml/document'
        require 'yaml'

        REPOMD_PATH = 'repodata/repomd.xml'

        # Fetch and parse modular metadata from a DNF repository
        #   Data can be fetched from https:// or a local directory
        #
        # @param [String] repo_url    base URL of modular repository
        # @param [String] repo_label  a string label unique to this repo
        #   This is used to
        # @return [Hash] The modular metadata of the repository
        # @return [nil] when the repo did not contain modular metadata
        def DnfRepo.fetch_modularity(repo_url, repo_label)
          # Fetch repomd.xml, get modulemd ("modules") file location & info
          repomd_url = "#{repo_url}/#{REPOMD_PATH}"
          puts "  -- fetching repomd: '#{repomd_url}'"
          repomd_content = FileFetcher.create(repomd_url).fetch
          # FIXME -- what if repo doesn't have modularity data?
          begin
            modulemd_md = DnfRepo.parse_repomd_modules(repomd_content)
          rescue NoMethodError
            warn( "  !! WARNING: No modularity metadata in '#{repo_url}'" )
            return nil
          end

          # fetch modulemd file and read modularity data
          modulemd_url  = "#{repo_url}/#{modulemd_md[:path]}"
          puts "  -- fetching modulemd: '#{modulemd_url}'"
          modulemd_content = FileFetcher.create(modulemd_url, modulemd_md).fetch
          data = YAML.load_stream(modulemd_content)
          ModularityData.new(data)
        end

        protected

        # @param [String] repomd XML data
        # @return [Hash] modulemd file metadata
        def DnfRepo.parse_repomd_modules(repomd_data)
          rexml = REXML::Document.new repomd_data

          # The .elements will be nil if anything wasn't found and cause .value
          # to raise a NoMethodError
          {
            path:           rexml.elements["/repomd/data[@type = 'modules']/location/@href"].value,
            checksum_type:  rexml.elements["/repomd/data[@type = 'modules']/checksum/@type"].value,
            checksum:       rexml.elements["/repomd/data[@type = 'modules']/checksum"].text,
            size:           rexml.elements["/repomd/data[@type = 'modules']/size"].text,
          }
        end
      end
    end
  end
end
