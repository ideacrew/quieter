cls = Class.new(Puma::Plugin)

cls.class_eval do
  def start(launcher)
    if Rails.env.development?
      fork do
        require 'vite_ruby'
        
        cli = ViteRuby::CLI
        cli.require_framework_libraries
        
        Dry::CLI.new(cli).call(arguments: ["dev"])
      end
    end
  end
end

Puma::Plugins.register("vite_dev_server", cls)