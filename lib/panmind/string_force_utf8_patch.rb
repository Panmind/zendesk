# Adds a .force_utf8 to the String class if running on 1.9,
# that forces the encoding to utf-8 and then normalizes in
# NFKC form.
#
# For now, we're using ActiveSupport because it is 33% faster
# than UnicodeUtils, but in the future you can never know.
#
# See http://www.cl.cam.ac.uk/~mgk25/unicode.html#ucsutf for
# details about on Unicode Normalization Forms.
#
# Returns ActiveSupport's mb_chars on Ruby 1.8.
#

unless 'the string'.respond_to?(:force_utf8)
  class String
    if '1.9'.respond_to?(:force_encoding)
      #require 'unicode_utils/nfkc'

      def force_utf8
        #force_encoding('UTF-8')
        #replace UnicodeUtils.nfkc(self)
        replace ActiveSupport::Multibyte::Chars.new(self).normalize(:kc)
      end
    else
      def force_utf8
        mb_chars.normalize(:kc)
      end
    end
  end
end
