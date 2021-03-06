# Copyright 2011 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You
# may not use this file except in compliance with the License. A copy of
# the License is located at
#
#     http://aws.amazon.com/apache2.0/
#
# or in the "license" file accompanying this file. This file is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
# ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.

require 'aws/s3/prefixed_collection'

module AWS
  class S3

    # @private
    module PrefixAndDelimiterCollection

      include PrefixedCollection

      def each(options = {}, &block)
        each_page(options) do |page|
          each_member_in_page(page, &block)
        end
        nil
      end

      # @see Bucket#as_tree
      def as_tree options = {}
        Tree.new(self, { :prefix => prefix }.merge(options))
      end

      # @private
      protected
      def each_member_in_page(page, &block)
        super
        page.common_prefixes.each do |p|
          yield(with_prefix(p))
        end
      end

      # @private
      protected
      def list_options(options)
        opts = super
        opts[:delimiter] = options[:delimiter] if options.key?(:delimiter)
        opts
      end

    end

  end
end
