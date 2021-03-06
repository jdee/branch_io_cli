module BranchIOCLI
  module Commands
    class ValidateCommand < Command
      def initialize(options)
        super
        config_helper.validate_validation_options options
      end

      def run!
        # raises
        xcodeproj = config_helper.xcodeproj

        valid = true

        unless options.domains.nil? || options.domains.empty?
          domains_valid = helper.validate_project_domains(
            options.domains,
            xcodeproj,
            options.target
          )

          if domains_valid
            say "Project domains match :domains parameter: ✅"
          else
            say "Project domains do not match specified :domains"
            helper.errors.each { |error| say " #{error}" }
          end

          valid &&= domains_valid
        end

        configuration_valid = helper.validate_team_and_bundle_ids_from_aasa_files xcodeproj, options.target
        unless configuration_valid
          say "Universal Link configuration failed validation."
          helper.errors.each { |error| say " #{error}" }
        end

        valid &&= configuration_valid

        say "Universal Link configuration passed validation. ✅" if valid

        valid
      end
    end
  end
end
