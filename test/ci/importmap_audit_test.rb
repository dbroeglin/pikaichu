require "minitest/autorun"
require "tmpdir"
require "fileutils"
require_relative "../../script/ci/importmap_audit"

class ImportmapAuditTest < Minitest::Test
  def setup
    @root = Pathname.new(Dir.mktmpdir("importmap-audit-test"))
    FileUtils.mkdir_p(@root.join("config"))
    FileUtils.mkdir_p(@root.join("vendor/javascript"))
    FileUtils.mkdir_p(@root.join("app/javascript"))
    @root.join("app/javascript/application.js").write("export {}")
    @root.join("vendor/javascript/example.js").write("export {}")
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_accepts_versioned_dependencies_and_application_owned_modules
    write_importmap <<~RUBY
      pin "application"
      pin "example", to: "example.js" # @1.2.3
    RUBY

    assert_equal [ [ "example", "1.2.3" ] ], audit.check!
  end

  def test_rejects_an_empty_audit_inventory
    write_importmap 'pin "application"'

    assert_raises(LocalCI::Error) { audit.check! }
  end

  def test_rejects_partially_versioned_dependencies
    @root.join("vendor/javascript/another.js").write("export {}")
    write_importmap <<~RUBY
      pin "example", to: "example.js" # @1.2.3
      pin "another", to: "another.js"
    RUBY

    error = assert_raises(LocalCI::Error) { audit.check! }
    assert_includes error.message, "another"
  end

  def test_rejects_unpinned_vendored_javascript
    @root.join("vendor/javascript/orphan.js").write("export {}")
    write_importmap 'pin "example", to: "example.js" # @1.2.3'

    error = assert_raises(LocalCI::Error) { audit.check! }
    assert_includes error.message, "orphan.js"
  end

  def test_rejects_a_missing_vendored_file_even_with_a_version
    write_importmap 'pin "missing", to: "missing.js" # @1.2.3'

    error = assert_raises(LocalCI::Error) { audit.check! }
    assert_includes error.message, "missing"
  end

  def test_does_not_exempt_application_files_that_shadow_vendor_files
    @root.join("app/javascript/example.js").write("export {}")
    write_importmap 'pin "example", to: "example.js"'

    assert_raises(LocalCI::Error) { audit.check! }
  end

  def test_repository_inventory_is_complete
    packages = LocalCI::ImportmapAudit.new(root: File.expand_path("../..", __dir__)).check!

    assert_equal %w[@hotwired/stimulus @hotwired/turbo sortablejs stimulus-autocomplete], packages.map(&:first).sort
  end

  private

  def write_importmap(content)
    @root.join("config/importmap.rb").write(content)
  end

  def audit
    LocalCI::ImportmapAudit.new(root: @root)
  end
end
