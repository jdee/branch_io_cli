module BranchIOCLI
  class CLI
    def initialize(args)
      Options.parse! args
    end

    def run
      # TODO: This
      puts Options.options
    end
  end
end
