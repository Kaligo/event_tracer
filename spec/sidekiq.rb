# This is a mock sidekiq module for testing purposes.

module Sidekiq
  module Worker
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def sidekiq_options(opts = {}); end
    end
  end
end
