require_relative "workspace"
require "active_support"
require "active_support/core_ext"
require "importmap-rails"
require "importmap/map"
require "importmap/npm"

module LocalCI
  class ImportmapAudit
    def initialize(root: File.expand_path("../..", __dir__))
      @root = Pathname.new(root)
    end

    def check!
      importmap_path = @root.join("config/importmap.rb")
      vendor_path = @root.join("vendor/javascript")
      map = Importmap::Map.new.draw(importmap_path)
      versions = Importmap::Npm.new(importmap_path, vendor_path: vendor_path).packages_with_versions
      raise Error, "Importmap audit inventory is empty; add accurate version metadata to third-party pins." if versions.empty?

      versioned_names = versions.map(&:first)
      vendor_files = vendor_path.glob("**/*.js")
      pinned_vendor_files = []

      map.packages.each_value do |package|
        file = vendor_path.join(package.path)
        if file.file?
          pinned_vendor_files << file
        elsif @root.join("app/javascript", package.path).file?
          next
        elsif !package.path.start_with?("https://")
          raise Error, "Importmap audit cannot locate #{package.name} (#{package.path})."
        end

        unless versioned_names.include?(package.name)
          raise Error, "Importmap audit is missing a version for #{package.name}."
        end
      end

      unpinned_files = vendor_files - pinned_vendor_files
      unless unpinned_files.empty?
        raise Error, "Importmap audit has unpinned vendor files: #{unpinned_files.map(&:basename).join(', ')}."
      end

      versions
    end
  end
end
