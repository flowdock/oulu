  class EmojiCleaner
    def self.perform content
      return content if not String === content
      content.split('').map do |ch|
        em = Emoji.name_for ch
        em ? ":#{em}:" : ch
      end.join('')
    end
  end
