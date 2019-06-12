class TelegramController < Telegram::Bot::UpdatesController
    include Telegram::Bot::UpdatesController::MessageContext
    include Telegram::Bot::UpdatesController::CallbackQueryContext
    before_action :set_locale
    before_action :find_chat
    
    include Help
    include Language
    include Hidden
    
    def start!
        language_from = "#{WORDREFERENCE_LANGUAGES[@chat_config.language_source.to_sym][:title]} #{WORDREFERENCE_LANGUAGES[@chat_config.language_source.to_sym][:icon]}"
        language_to = "#{WORDREFERENCE_LANGUAGES[@chat_config.language_translation.to_sym][:title]} #{WORDREFERENCE_LANGUAGES[@chat_config.language_translation.to_sym][:icon]}"
        text = "Hi, Welcome to your translation dictionary 📖\n" \
               "\nWe will translate from *#{language_from}* to *#{language_to}*. \n" \
               "but you can change the language anytime with /language \n" \
               "\n We use online dictionaries sources such as:  \n" \
               "- Wordreference.com \n" \
               "\n------- \n" \
               "Complete list of commands: \n " \
               "/language: Change Language translation  \n" \
               "/source: Change source dictionary \n" \
               "/config: See current configuration \n" \
               "/help: Get help\n" \

        respond_with :message, text: text, parse_mode: 'Markdown'
    end
  
    def message(message)
        message_text = message[:text].gsub EMOJI_REGEX, ''
        if message_text.length == 0
            return respond_with :message, text: 'No emojis pls 😡', parse_mode: 'Markdown'        
        end
        r = Rserve::Simpler.new
        r.command "source('#{Rails.root}/script.R')"
        a = r.converse ('x')
        puts a
        language_from = WORDREFERENCE_LANGUAGES[@chat_config.language_source.to_sym][:icon]
        language_to = "#{t("languages.#{@chat_config.language_translation}")} #{WORDREFERENCE_LANGUAGES[@chat_config.language_translation.to_sym][:icon]}"
        text = "#{language_from} *#{message_text}* to #{language_to}: \n" \
        "- Hola: Hi"
        
        respond_with :message, text: text, parse_mode: 'Markdown'       
    
    rescue => e
        puts e.message
        respond_with :message, text: t('app.error'), parse_mode: 'Markdown'       
    ensure
    end

    private

    def find_chat
        @chat_config = Chat.find_or_create_by(telegram_chat_id: from['id']) do |chat|
            if from['language_code'] == 'en'
                chat.language_source = 'es'
                chat.language_translation = 'en'
            else
                chat.language_source = 'en'
                chat.language_translation = from['language_code']
            end
        end
    end 

    def set_locale
        I18n.locale = I18n.available_locales.map(&:to_s).include?(from[:language_code]) ? from[:language_code] : 'en'
    end

  end