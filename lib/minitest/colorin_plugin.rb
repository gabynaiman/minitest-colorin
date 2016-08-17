module Minitest

  def self.plugin_colorin_options(opts, options)
  end

  def self.plugin_colorin_init(options) 
    self.reporter.reporters = []
    self.reporter << Colorin.new(options.fetch(:io, STDOUT))
  end

end