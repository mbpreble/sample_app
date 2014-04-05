# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  email      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class User < ActiveRecord::Base
  attr_accessible :email, :name, :password, :password_confirmation
  
  validates :name, presence: true, length: { maximum: 50}
  
  validates :password, length: {minimum: 6}
  
  validates :password_confirmation, presence: true
  
  has_secure_password
  has_many :microposts, dependent: :destroy
  has_many :relationships, foreign_key: "follower_id", dependent: :destroy  
  has_many :reverse_relationships, foreign_key:"followed_id", 
    class_name: "Relationship", dependent: :destroy
  
  has_many :followed_users, through: :relationships, source: :followed
  has_many :followers, through: :reverse_relationships, source: :follower

  
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, 
  		uniqueness: { case_sensitive: false }
  
  before_save { email.downcase! } 
  before_create :create_remember_token
  
  def User.new_remember_token
  	SecureRandom.urlsafe_base64
  end
  
  def User.encrypt(token)
  	Digest::SHA1.hexdigest(token.to_s)
  end
  
  def feed
    Micropost.from_users_followed_by(self)
  end

  def following?(other_user)
    relationships.find_by(followed_id: other_user.id)
  end

  def follow!(other_user)
    relationships.create(followed: other_user)
  end

  def unfollow!(other_user)
    relationships.find_by(followed_id: other_user.id).destroy
  end

  private
  
  	def create_remember_token
  		self.remember_token = User.encrypt(User.new_remember_token)
  	end
end
