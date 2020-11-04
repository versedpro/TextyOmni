class Api::V1::Widget::MessagesController < Api::V1::Widget::BaseController
  protect_from_forgery with: :null_session
  
  before_action :set_conversation, only: [:create]
  before_action :set_message, only: [:update]

  def index
    @messages = conversation.nil? ? [] : message_finder.perform
  end

  def create
    @message = conversation.messages.new(message_params)
    @message.save
    build_attachment
  end

  def update
    if @message.content_type == 'input_email'
      @message.update!(submitted_email: contact_email)
      update_contact(contact_email)
    elsif @message.content_type == 'form'
      @message.update!(message_update_params[:message])
      update_contact(contact_email_original, contact_name_original, contact_phone_number)
    elsif @message.content_type == 'input_phone'
    	# @message.update!(submitted_phone: permitted_params[:contact][:phone])
    	update_contact(nil, nil, permitted_params[:contact][:phone])
    else 
    	# Call options from parameter
    	call_option if message_update_params[:message][:submitted_values].length() == 1
    	
      @message.update!(message_update_params[:message])
    end
  # rescue StandardError => e
  #   render json: { error: @contact.errors, message: e.message }.to_json, status: 500
  end

  private

  def build_attachment
    return if params[:message][:attachments].blank?

    params[:message][:attachments].each do |uploaded_attachment|
      attachment = @message.attachments.new(
        account_id: @message.account_id,
        file_type: helpers.file_type(uploaded_attachment&.content_type)
      )
      attachment.file.attach(uploaded_attachment)
    end
    Rails.logger.debug "MESSAGE WILL BE SAVED WITH #{@message}"
    @message.save!
  end

  def set_conversation
    @conversation = ::Conversation.create!(conversation_params) if conversation.nil?
  end

  def message_params
    {
      account_id: conversation.account_id,
      sender: @contact,
      content: permitted_params[:message][:content],
      inbox_id: conversation.inbox_id,
      echo_id: permitted_params[:message][:echo_id],
      message_type: :incoming
    }
  end

  def conversation_params
    {
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: {
        browser: browser_params,
        referer: permitted_params[:message][:referer_url],
        initiated_at: timestamp_params
      }
    }
  end

  def timestamp_params
    {
      timestamp: permitted_params[:message][:timestamp]
    }
  end

  def inbox
    @inbox ||= ::Inbox.find_by(id: auth_token_params[:inbox_id])
  end

  def message_finder_params
    {
      filter_internal_messages: true,
      before: permitted_params[:before]
    }
  end

  def message_finder
    @message_finder ||= MessageFinder.new(conversation, message_finder_params)
  end

  def update_contact(email=nil, name=nil, phone_number=nil)
    if email
      contact_with_email = @current_account.contacts.find_by(email: email)
      
      if contact_with_email
        @contact = ::ContactMergeAction.new(
          account: @current_account,
          base_contact: contact_with_email,
          mergee_contact: @contact
        ).perform
      elsif name
        @contact.update!(
          email: email,
          name: name
        )
      else
        @contact.update!(
          email: email,
          name: contact_name
        )
      end
    end
    
    if name
      @contact.update!(
        name: name,
        phone_number: phone_number
      )
    end
    
    if phone_number
    	@contact.update!(
    		phone_number: phone_number
    	)
    end
  end

  def contact_email
    permitted_params[:contact][:email].downcase
  end

  def contact_email_original
    permitted = params.permit(message: [{submitted_values: :value}])
    permitted[:message][:submitted_values][1][:value]
  end

  def contact_name_original
    permitted = params.permit(message: [{submitted_values: :value}])
    permitted[:message][:submitted_values][0][:value]
  end

  def contact_name
    contact_email.split('@')[0]
  end
  
  def contact_phone_number 
    permitted = params.permit(message: [{submitted_values: :value}])
    permitted[:message][:submitted_values][2][:value]
  end

  def message_update_params
    params.permit(message: [{ submitted_values: [:name, :title, :value] }])
  end

  def permitted_params
    params.permit(:id, :before, :website_token, contact: [:email, :phone], message: [:content, :referer_url, :timestamp, :echo_id])
  end

  def set_message
    @message = @web_widget.inbox.messages.find(permitted_params[:id])
  end
  
  def call_option
  	message_update_params[:message][:submitted_values][0][:title] == 'call back later' ? call_back_message : voice_chat
  end
  
  def call_back_message
  	@call_back_message = conversation.messages.new(call_back_message_params)
  	@call_back_message.save
  end
  
  def voice_chat
  	# Todo for WebRTC voice chat
  end
  
  def call_back_message_params
  	
    {
      account_id: conversation.account_id,
      # content_attributes: call_back_contents,
      inbox_id: conversation.inbox_id,
      message_type: :template,
      content: message_update_params[:message][:submitted_values][0][:value],
      content_type: :input_phone
    }
  end
end
