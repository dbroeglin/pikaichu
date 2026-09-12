require "minitest/autorun"
require "yaml"

class TranslationsTest < Minitest::Test
  def test_i18n_tasks_reads_all_application_locale_files
    root = File.expand_path("../..", __dir__)
    config = YAML.load_file(File.join(root, "config/i18n-tasks.yml"))
    locale_files = Dir.glob("config/locales/**/*.yml", base: root).sort
    configured_files = config.fetch("locales").flat_map do |locale|
      config.fetch("data").fetch("read").flat_map do |pattern|
        Dir.glob(format(pattern, locale: locale), base: root)
      end
    end.uniq.sort

    refute_empty locale_files
    assert_equal locale_files, configured_files
  end
end
