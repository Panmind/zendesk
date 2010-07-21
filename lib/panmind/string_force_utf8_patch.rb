# Adds a .force_utf8 to the String class: it forces the instance
# encoding to utf-8 and then normalizes in NFKC form.
#
# For now, we're using ActiveSupport because it has proven to be
# 33% faster than UnicodeUtils.. but in the future you can never
# know whether the AS::Multibyte::Chars class will be supported.
#
# Please read http://www.cl.cam.ac.uk/~mgk25/unicode.html#ucsutf
# for more information about Unicode Normalization Forms.
#
#   - vjt  Wed Jul 21 16:51:25 CEST 2010
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
        replace mb_chars.normalize(:kc)
      end
    end
  end
end
