class TelegramController < Telegram::Bot::UpdatesController
    include Telegram::Bot::UpdatesController::MessageContext
    include Telegram::Bot::UpdatesController::CallbackQueryContext
    
    before_action :set_locale
    before_action :find_chat
    
    include Config
    include Help
    include Hidden
    include Language
    include Report
    include Swap
    
    def start!
        language_from = "#{WORDREFERENCE_LANGUAGES[@chat_config.language_source.to_sym][:title]} #{WORDREFERENCE_LANGUAGES[@chat_config.language_source.to_sym][:icon]}"
        language_to = "#{WORDREFERENCE_LANGUAGES[@chat_config.language_translation.to_sym][:title]} #{WORDREFERENCE_LANGUAGES[@chat_config.language_translation.to_sym][:icon]}"
        text = I18n.t('app.messages.welcome', { language_from: language_from, language_to: language_to})        
        respond_with :message, text: text, parse_mode: 'Markdown'
    end
  
    def message(message)
        message_text = message[:text].downcase.gsub EMOJI_REGEX, ''
        if message_text.length == 0
            return respond_with :message, text: 'No emojis pls 😡', parse_mode: 'Markdown'        
        end

        text = Scraper.new(ENV.fetch('SCRAPER_SERVICE') { 'scraperapi' }).make_request(@chat_config, message_text)
        respond_with :message, text: text, parse_mode: 'Markdown'       

    rescue => e
        Raven.capture_exception(e.message)
        respond_with :message, text: t('app.error'), parse_mode: 'Markdown'       
    ensure
    end

    private

    def find_chat
        @chat_config = Chat.find_or_create_by(telegram_chat_id: from['id']) do |chat|
            chat.first_name = from['first_name']
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