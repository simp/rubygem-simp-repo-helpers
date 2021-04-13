require_relative 'file_fetcher'
module Simp
  module Repo
    module Helpers
      class WebFileFetcher < FileFetcher
        def _fetch
          doc = @uri.open
          @opts[:gunzip] = true if (doc.metas['content-type'] == ['application/x-gzip'])
          if @opts[:gunzip] && doc.metas['content-type'] != ['application/x-gzip']
            fail("expected '#{@url}' to be application/x-gzip!")
          end
          doc.read
        end
      end
    end
  end
end
