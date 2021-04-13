require_relative 'file_fetcher'
module Simp
  module Repo
    module Helpers
      class LocalFileFetcher < FileFetcher
        def _fetch
          File.open(@uri.to_s,'r').read
        end
      end
    end
  end
end
