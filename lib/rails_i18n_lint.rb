require 'active_support'
require 'active_support/core_ext/hash/deep_merge'
require 'hashdiff'

require 'pathname'
require 'yaml'
require 'pp'


require "rails_i18n_lint/version"

module RailsI18nLint
  extend self

  def run
    t = targets('./')
    t.each do |dir, files|
      yamls = files
        .map{|f| YAML.load_file(f)}
        .map{|x| x.map{|lang, value| [lang, value]}}
        .flatten(1)
      sum = hash_sum(yamls.map{|_, value|value})

      yamls.each do |lang, value|
        diff = HashDiff.diff(sum, value).select{|diff| diff[0] == '-'}
        next if diff.empty?

        puts "> Detect not enough fields in #{dir} #{lang}"
        diff.each do |d|
          puts d[1]
        end
        puts
      end
    end
  end

  # @param [Array<Hash>] hashes
  def hash_sum(hashes)
    hashes.inject({}) do |sum, h|
      sum.deep_merge!(h)
      sum
    end
  end

  # @param [String] root
  # @return [Hash{String => Array<String>}] paths
  def targets(root)
    glob = Pathname.new(root).join('config/locales/**/*.yml').to_s
    paths = Dir.glob(glob)
    paths.group_by{|x| File.dirname(x)}
  end
end
