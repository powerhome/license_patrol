# frozen_string_literal: true

module LicensePatrol
  class License
    module Text
      SPACES = /\s+/
      QUOTES = /['`"]{1,2}/
      YEAR_PLACEHOLDERS = /<year>/
      PLACEHOLDERS = /<[^<>]+>/
      SPECIAL_SINGLE_QUOTES = /[‘’]/
      SPECIAL_DOUBLE_QUOTES = /[“”„«»]/
      ALPHABET_ORDERED_LIST = /\\\([a-z]\\\)\\\s/
      ALPHABET_ORDERED_LIST_OPTIONAL = '(\([a-z]\)\s)?'
      LIST_BULLETS = /(\d{1,2}\\\.|\\\*|\\-)\\\s/
      LIST_BULLETS_OPTIONAL = '(\d{1,2}.|\*|\-)?\s*'
      NEWLINE_CHARACTER = /\n+/
      QUOTE_COMMENT_CHARACTER = /^\s*>+/
      ESCAPED_QUOTES = /\\"/
      SPECIAL_CHARACTERS = /§/
      SPECIAL_DASHES = /–/

      def self.normalize_punctuation(text)
        text.dup.force_encoding('UTF-8')
            .gsub(SPECIAL_DOUBLE_QUOTES, '"')
            .gsub(SPECIAL_SINGLE_QUOTES, "'")
            .gsub(QUOTE_COMMENT_CHARACTER, '')
            .gsub(SPACES, ' ')
            .gsub(NEWLINE_CHARACTER, ' ')
            .gsub(ESCAPED_QUOTES, '"')
            .gsub(QUOTES, '"')
            .gsub(SPECIAL_CHARACTERS, '?')
            .gsub(SPECIAL_DASHES, '-')
            .strip
      rescue ArgumentError => _e
        text
      end

      def self.compile_to_regex(text)
        Regexp.new(Regexp.escape(normalize_punctuation(text))
                       .gsub(YEAR_PLACEHOLDERS, '(\S*)')
                       .gsub(PLACEHOLDERS, '(.*)')
                       .gsub(',', '(,)?')
                       .gsub('HOLDER', '(HOLDER|OWNER)')
                       .gsub(ALPHABET_ORDERED_LIST, ALPHABET_ORDERED_LIST_OPTIONAL)
                       .gsub(LIST_BULLETS, LIST_BULLETS_OPTIONAL))
      end
    end
  end
end
