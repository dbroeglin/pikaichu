module DownloadHelpers
  TIMEOUT = 15
  PATH = Rails.root.join("tmp/downloads")

  def downloads
    Dir[PATH.join("*")]
  end

  def last_download
    wait_for_download
    downloads.last
  end

  def last_download_contents
    File.read(last_download)
  end

  def clear_downloads
    FileUtils.rm_f(downloads)
  end

  private

  def wait_for_download
    Timeout.timeout(TIMEOUT) do
      sleep 0.1 until downloaded?
    end
  end

  def downloaded?
    !downloading? && downloads.any?
  end

  def downloading?
    downloads.grep(/\.crdownload$/).any?
  end
end
