module Simp
  module Repo
    module Helpers
      class ModularityData
        attr_accessor :modulemd_data, :modules, :verbose
        def initialize(modulemd_data)
          @modulemd_data = modulemd_data.dup
          @modules = parse_modulemd_stream(@modulemd_data)
          @verbose = false
        end

        # Parse supported libmodulemd documents, return modules data
        #
        # Supported document types:
        #
        #   | Document type     | Version | Notes |
        #   | -------------     | ------- | ----- |
        #   | modulemd          |  2      | https://github.com/fedora-modularity/libmodulemd/blob/main/yaml_specs/modulemd_stream_v2.yaml   |
        #   | modulemd-defaults |  1      | https://github.com/fedora-modularity/libmodulemd/blob/main/yaml_specs/modulemd_defaults_v1.yaml |
        #
        # @param [Hash] modulemd_stream  Hash of libmodulemd documents, as loaded
        #    from a DNF repo's modules.yaml.gz
        # @return [Hash] combined data for each module, including streams and defaults
        #
        def parse_modulemd_stream(modulemd_stream)
          modules = {}
          modulemd_stream.each do |doc|
            x = doc['data']
            if doc['document'] == 'modulemd' && doc['version'] == 2
              n     = x['name']
              ns    = "#{n}:#{x['stream']}"
              nsv   = "#{ns}:#{x['version']}"
              nsvc  = "#{nsv}:#{x['context']}"
              nsvca = "#{nsvc}:#{x['arch']}"
              modules[n]            ||= {}
              modules[n]['streams'] ||= {}
              streams = modules[n]['streams']

              # This shouldn't happen in a single repo, but I haven't seen that it's no permitted...
              warn("  ?? WARNING: Module '#{n}' NSVCA stream already defined: '#{nvsca}'") if streams.key?(nsvca)
              streams[nsvca] = doc['data']
              warn "  -- modulemd: #{nsvca}" if @verbose
            elsif doc['document'] == 'modulemd-defaults' && doc['version'] == 1
              n = x['module']
              modules[n] ||= {}
              modules[n]['defaults'] ||= {}
              modules[n]['defaults'].merge!(x.select{|k,v| k != 'module' })
              warn "  -- modulemd-defaults: '#{n}'" if @verbose
            else
              fail("ERROR: Document version not supported: '#{doc['document']}', version #{doc['version']}")
            end
          end
          modules
        end

        def to_s
          modules = @modules ###.sort_by{|k,v| -v['streams'].size }.to_h
          s = <<~TO_S
            YAML multiple-stream documents: #{@modulemd_data.size}

            ## Modules (#{modules.size})
            #{
              max = modules.keys.map(&:size).max
              "    #{'Name'.ljust(max)}  Streams\n" + \
              "    #{'----'.ljust(max)}  -------\n" + \
              modules.map do |k,v|
                "    #{k.ljust(max)}  #{v['streams'].size.to_s.ljust(2)}"
              end.join("\n")
            }
          TO_S
        end
      end
    end
  end
end
