# frozen_string_literal: true

module WebpackerLoadYamlWithAliases
  private

  def defaults
    @defaults ||= HashWithIndifferentAccess.new(
      YAML.load_file(
        "#{Gem.loaded_specs['webpacker'].full_gem_path}/lib/install/config/webpacker.yml",
        aliases: true
      )[env]
    )
  end
end

Webpacker::Configuration.prepend(WebpackerLoadYamlWithAliases)
