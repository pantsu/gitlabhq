class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :lockable, :timeoutable,
  # :database_authenticatable, :registerable, recoverable,
  # :validatable and :confirmable
  devise :omniauthable, :rememberable, :trackable, :database_authenticatable, :timeoutable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, 
                  :name, :projects_limit, :skype, :linkedin, :twitter

  has_many :users_projects, :dependent => :destroy
  has_many :projects, :through => :users_projects
  has_many :my_own_projects, :class_name => "Project", :foreign_key => :owner_id
  has_many :keys, :dependent => :destroy
  has_many :authentications, :dependent => :destroy
  has_many :issues,
    :foreign_key => :author_id,
    :dependent => :destroy

  has_many :assigned_issues,
    :class_name => "Issue",
    :foreign_key => :assignee_id,
    :dependent => :destroy

  scope :not_in_project, lambda { |project|  where("id not in (:ids)", :ids => project.users.map(&:id) ) }

  before_validation :generate_password, :on => :create

  scope :online, lambda { where("updated_at > ?", 15.seconds.ago) }

  def generate_password
    o =  [('a'..'z'), ('A'..'Z'), (0..9)].map{|i| i.to_a}.flatten
    self.password = self.password_confirmation = (0..16).map{ o[rand(o.length)] }.join if self.password.blank?
  end

  def identifier
    email.gsub "@", "_"
  end

  def is_admin?
    admin
  end

  def can_create_project?
    projects_limit >= my_own_projects.count
  end

  def last_activity_project
    projects.first
  end

  def self.find_for_ldap_auth(omniauth)
    # ACCOUNTDISABLE = 2
    # LOCKOUT = 16
    # PASSWORD_EXPIRED = 8388608
    if (omniauth["extra"][:useraccountcontrol][0].to_i & (2 | 16 | 8388608) == 0)
      authentication = Authentication.find_by_provider_and_uuid(omniauth['provider'], omniauth["extra"][:dn].to_a.first.to_s)
      if authentication && authentication.user
        authentication.user.update_attribute(:name, omniauth["extra"][:displayname][0])
        authentication.user
      else
        user = User.find_or_create_by_email(omniauth["extra"][:mail][0])
        user.update_attribute(:name, omniauth["extra"][:displayname][0])
        user.authentications.build(:provider => omniauth['provider'], :uuid => omniauth["extra"][:dn].to_a.first.to_s)
        user.save
        user
      end
    else
      User.new
    end
  end

end
# == Schema Information
#
# Table name: users
#
#  id                     :integer         not null, primary key
#  email                  :string(255)     default(""), not null
#  encrypted_password     :string(128)     default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer         default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  name                   :string(255)
#  admin                  :boolean         default(FALSE), not null
#  projects_limit         :integer
#  skype                  :string
#  linkedin               :string
#  twitter                :string
#

