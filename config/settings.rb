require 'settingslogic'

module Datanet
  module Skel
    module Mongodb
      class Settings < Settingslogic

        class << self
          def config_file
            settings = config_file_path('config.yml')
            File.exists?(settings) ? settings : config_file_path('default_config.yml')
          end

          private
          def config_file_path(file_name)
            File.join(File.dirname(__FILE__), file_name)
          end
        end

        source config_file
        load!

      end
    end
  end
end
