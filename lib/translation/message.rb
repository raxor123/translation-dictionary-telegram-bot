module Translation
    class Message
        def self.generate(r, chat_config, message_text, key_cache)
            from_word_unformatted =  r.get_var('from_word')
            to_word_unformatted =  r.get_var('to_word')
            language_source =  r.get_var('language_source')
            language_translation =  r.get_var('language_translation')

            from_word_formatted = from_word_unformatted.class == Array ?  from_word_unformatted.uniq.map(&:strip).reject(&:empty?).join(', ') : from_word_unformatted
            to_word_formatted = to_word_unformatted.class == Array ?  to_word_unformatted.uniq.map(&:strip).reject(&:empty?).join(', ') : to_word_unformatted
            
            if from_word_formatted.empty? || to_word_formatted.empty?
                Rails.cache.fetch(key_cache, expires_in: 12.hours) { I18n.t('app.messages.error', {message_text: message_text}) }
                return I18n.t('app.messages.error', {message_text: message_text})
            end
            
            result = "- #{from_word_formatted}: #{to_word_formatted} \n"

            languages_codify = "#{language_source}***#{language_translation}***"

            text = "#{languages_codify}" +
                result +
                "\nTranslation made from: wordreference.com"
                
            if language_source != chat_config.language_source
                key_cache += ":swap"
            end
                
            Rails.cache.fetch(key_cache, expires_in: 12.hours) { text }
            return text
        end
    end
end
