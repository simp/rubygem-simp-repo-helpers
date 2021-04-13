module Simp
  module Repo
    module Helpers
      class FileFetcher
        require 'open-uri'
        require 'zlib'
        require_relative 'web_file_fetcher'
        require_relative 'local_file_fetcher'
        require_relative 'modularity_data'

        def FileFetcher.create(url, opts={})
          uri = URI.parse(url)
          uri.class == URI::Generic ? LocalFileFetcher.new(uri,opts) : WebFileFetcher.new(uri,opts)
        end

        def initialize(uri,opts)
          @uri = uri
          @opts = opts.dup
        end

        def fetch
          @opts[:gunzip] = @uri.to_s.match?(/\.gz$/)
          data = _fetch
          check_size(@opts[:size], data.size.to_s) if @opts[:size]
          check_checksum(@opts[:checksum], @opts[:checksum_type], data) if @opts[:checksum]
          @opts[:gunzip] ? gunzip(data) : data
        end

        def gunzip(data)
          window_size = Zlib::MAX_WBITS + 16 # decode only gzip
          Zlib::Inflate.new(window_size).inflate(data)
        end

        def check_size(target_size, data_size)
          unless data_size.to_s == target_size
            fail("Data size (#{data_size}) was expected to be '#{target_size}'")
          end
          warn "-- Data size was as-expected: '#{data_size}'"
        end

        def check_checksum(expected_checksum, checksum_type,  data)
          digest_bits = checksum_type.sub(/^sha/,'')
          unless ['256','384','512'].include? digest_bits
            fail("Data checksum for type '#{expected_checksum}' not implemented")
          end

          require 'digest'
          computed_checksum = Digest::SHA2.new(digest_bits.to_i).hexdigest(data)
          unless computed_checksum == expected_checksum
            fail([
              "Data #{checksum_type} checksum did not match!",
              "     Expected Checksum: #{expected_checksum}",
              "     Data Checksum:     #{computed_checksum}",
            ].join("\n"))
          end
          warn "-- Checksum was as-expected: '#{expected_checksum}'"
        end
      end
    end
  end
end
