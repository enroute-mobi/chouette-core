# frozen_string_literal: true

# Provides methods for Controllers which send files retrieve from CarrierWave
module Downloadable
  extend ActiveSupport::Concern

  # Cache locally the file of the given source.
  # To be used before any send_file in Controllers
  def prepare_for_download(source)
    Chouette::Benchmark.measure 'prepare_download', id: source.id, type: source.class.name do
      Chouette::Benchmark.measure 'cache_stored_file' do
        source.file.cache! unless source.file.cached?
      end
      Chouette::Benchmark.measure 'clean_cached_files' do
        CarrierWave.clean_cached_files!
      end
    end
  end
end
