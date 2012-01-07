class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  has_one :user_has_role
  has_one :role, :through => :user_has_role
  has_one :patron
  belongs_to :user_group
  belongs_to :required_role, :class_name => 'Role', :foreign_key => 'required_role_id'
  has_many :sent_messages, :foreign_key => 'sender_id', :class_name => 'Message'
  has_many :received_messages, :foreign_key => 'receiver_id', :class_name => 'Message'
  before_create :set_role_and_patron

  extend FriendlyId
  friendly_id :username

  def set_role_and_patron
    self.required_role = Role.where(:name => 'Librarian').first
    self.locale = I18n.default_locale.to_s
    unless self.patron
      self.patron = Patron.create(:full_name => self.username) if self.username
    end
  end

  def has_role?(role_in_question)
    return false unless role
    return true if role.name == role_in_question
    case role.name
    when 'Administrator'
      return true
    when 'Librarian'
      return true if role_in_question == 'User'
    else
      false
    end
  end

  def send_message(status, options = {})
    MessageRequest.transaction do
      request = MessageRequest.new
      request.sender = User.find(1)
      request.receiver = self
      request.message_template = MessageTemplate.localized_template(status, self.locale)
      request.save_message_body(options)
      request.sm_send_message!
    end
  end
end
