require "rubygems"
require "commander"

module BranchIOCLI
  class CLI
    include Commander::Methods

    def run
      program :name, "Branch.io command-line interface"
      program :version, VERSION
      program :description, <<EOF
Command-line tool to integrate the Branch SDK into mobile app projects (currently
iOS only) and validate Universal Link domains
EOF

      command :setup do |c|
        c.syntax = "branch_io setup [OPTIONS]"
        c.summary = "Integrates the Branch SDK into a native app project"
        c.description = <<EOF
Integrates the Branch SDK into a native app project. This currently supports iOS only.
It will infer the project location if there is exactly one .xcodeproj anywhere under
the current directory, excluding any in a Pods or Carthage folder. Otherwise, specify
the project location using the <%= color('--xcodeproj', BOLD) %> option, or the CLI will prompt you for the
location.

If a Podfile or Cartfile is detected, the Branch SDK will be added to the relevant
configuration file and the dependencies updated to include the Branch framework.
This behavior may be suppressed using <%= color('--no-add-sdk', BOLD) %>. If no Podfile or Cartfile
is found, and Branch.framework is not already among the project's dependencies,
you will be prompted for a number of choices, including setting up CocoaPods or
Carthage for the project or directly installing the Branch.framework.

By default, all supplied Universal Link domains are validated. If validation passes,
the setup continues. If validation fails, no further action is taken. Suppress
validation using <%= color('--no-validate', BOLD) %> or force changes when validation fails using
<%= color('--force', BOLD) %>.

By default, this command will look for the first app target in the project. Test
targets are not supported. To set up an extension target, supply the <%= color('--target', BOLD) %> option.

All relevant target settings are modified. The Branch keys are added to the Info.plist,
along with the <%= color('branch_universal_link_domains', BOLD) %> key for custom domains (when <%= color('--domains', BOLD) %>
is used). For app targets, all domains are added to the project's Associated Domains
entitlement. An entitlements file is also added for app targets if none is found.
Optionally, if <%= color('--frameworks', BOLD) %> is specified, this command can add a list of system
frameworks to the target's dependencies (e.g., AdSupport, CoreSpotlight, SafariServices).

A language-specific patch is applied to the AppDelegate (Swift or Objective-C).
This can be suppressed using <%= color('--no-patch-source', BOLD) %>.

<%= color('Prerequisites', BOLD) %>

Before using this command, make sure to set up your app in the Branch Dashboard
(https://dashboard.branch.io). See https://docs.branch.io/pages/dashboard/integrate/
for details. To use the <%= color('setup', BOLD) %> command, you need:

- Branch key(s), either live, test or both
- Domain name(s) used for Branch links
- Location of your Xcode project (may be inferred in simple projects)

To use the <%= color('--commit', BOLD) %> option, you must have the <%= color('git', BOLD) %> command available in your path.

To add the SDK with CocoaPods or Carthage, you must have the <%= color('pod', BOLD) %> or <%= color('carthage', BOLD) %>
command, respectively, available in your path.

All parameters are optional. A live key or test key, or both is required, as well
as at least one domain. Specify <%= color('--live-key', BOLD) %>, <%= color('--test-key', BOLD) %> or both and <%= color('--app-link-subdomain', BOLD) %>,
<%= color('--domains', BOLD) %> or both. If these are not specified, this command will prompt you
for this information.

See https://github.com/BranchMetrics/branch_io_cli#setup-command for more information.
EOF

        # Required Branch params
        c.option "-L", "--live-key key_live_xxxx", String, "Branch live key"
        c.option "-T", "--test-key key_test_yyyy", String, "Branch test key"
        c.option "--app-link-subdomain myapp", String, "Branch app.link subdomain, e.g. myapp for myapp.app.link"
        c.option "-D", "--domains example.com,www.example.com", Array, "Comma-separated list of custom domain(s) or non-Branch domain(s)"
        c.option "-U", "--uri-scheme myurischeme[://]", String, "Custom URI scheme used in the Branch Dashboard for this app"

        c.option "--xcodeproj MyProject.xcodeproj", String, "Path to an Xcode project to update"
        c.option "--target MyAppTarget", String, "Name of a target to modify in the Xcode project"
        c.option "--podfile /path/to/Podfile", String, "Path to the Podfile for the project"
        c.option "--cartfile /path/to/Cartfile", String, "Path to the Cartfile for the project"
        c.option "--frameworks AdSupport,CoreSpotlight,SafariServices", Array, "Comma-separated list of system frameworks to add to the project"

        c.option "--[no-]pod-repo-update", "Update the local podspec repo before installing (default: yes)"
        c.option "--[no-]validate", "Validate Universal Link configuration (default: yes)"
        c.option "--[no-]force", "Update project even if Universal Link validation fails (default: no)"
        c.option "--[no-]add-sdk", "Add the Branch framework to the project (default: yes)"
        c.option "--[no-]patch-source", "Add Branch SDK calls to the AppDelegate (default: yes)"
        c.option "--[no-]commit", "Commit the results to Git (default: no)"

        c.example "Test without validation (can use dummy keys and domains)", "branch_io setup -L key_live_xxxx -D myapp.app.link --no-validate"
        c.example "Use both live and test keys", "branch_io setup -L key_live_xxxx -T key_test_yyyy -D myapp.app.link"
        c.example "Use custom or non-Branch domains", "branch_io setup -D myapp.app.link,example.com,www.example.com"
        c.example "Avoid pod repo update", "branch_io setup --no-pod-repo-update"

        c.action do |args, options|
          options.default(
            # Defaults for boolean options
            pod_repo_update: true,
            validate: true,
            force: false,
            add_sdk: true,
            patch_source: true,
            commit: false
          )
          Commands::SetupCommand.new(options).run!
        end
      end

      command :validate do |c|
        c.syntax = "branch_io validate [OPTIONS]"
        c.summary = "Validates all Universal Link domains configured in a project"
        c.description = <<EOF
This command validates all Universal Link domains configured in a project without making any
modification. It validates both Branch and non-Branch domains. Unlike web-based Universal
Link validators, this command operates directly on the project. It finds the bundle and
signing team identifiers in the project as well as the app's Associated Domains. It requests
the apple-app-site-association file for each domain and validates the file against the
project's settings.

Only app targets are supported for this command. By default, it will validate the first.
If your project has multiple app targets, specify the <%= color('--target', BOLD) %> option to validate other
targets.

All parameters are optional. If <%= color('--domains', BOLD) %> is specified, the list of Universal Link domains in
the Associated Domains entitlement must exactly match this list, without regard to order. If
no <%= color('--domains', BOLD) %> are provided, validation passes if at least one Universal Link domain is
configured and passes validation, and no Universal Link domain is present that does not pass
validation.

See https://github.com/BranchMetrics/branch_io_cli#validate-command for more information.
EOF

        c.option "-D", "--domains example.com,www.example.com", Array, "Comma-separated list of domains to validate (Branch domains or non-Branch domains)"
        c.option "--xcodeproj MyProject.xcodeproj", String, "Path to an Xcode project to update"
        c.option "--target MyAppTarget", String, "Name of a target to modify in the Xcode project"

        c.action do |args, options|
          valid = Commands::ValidateCommand.new(options).run!
          exit_code = valid ? 0 : 1
          exit exit_code
        end
      end

      run!
    end
  end
end
