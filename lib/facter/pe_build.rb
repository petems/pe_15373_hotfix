unless Kernel.respond_to?(:require_relative)
  module Kernel
    def require_relative(path)
      require File.join(File.dirname(caller[0]), path.to_str)
    end
  end
end

require_relative '../shared/pe_build'

module PEBuildCustomFact
  def self.add_fact
    Facter.add("pe_build") do
      setcode do
        PEBuild.get_pe_build
      end
    end
  end
end

PEBuildCustomFact.add_fact
