# == Schema Information
#
# Table name: users
#
#  email                  :string           not null, primary key
#  name                   :string
#  affiliation            :string
#  user_type              :string
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  admin                  :boolean          default(FALSE)
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

class User < ActiveRecord::Base
  self.primary_key = 'email'

  devise :database_authenticatable,
         :recoverable,
         :trackable

  has_many :changesets, foreign_key: :author_email

  validates :email, presence: true

  extend Enumerize
  enumerize :user_type, in: [
    :community_builder,
    :data_enthusiast,
    :app_developer,
    :hardware_vendor,
    :consultant,
    :transit_agency_staff,
    :other_public_agency_staff
  ]

  before_update :update_email_on_changesets

  def update_email_on_changesets
    if email_changed?
      Changeset.where(author_email: email_change.first).update_all(author_email: email_change.second)
    end
  end

  include CanBeSerializedToCsv
  def self.csv_column_names
    [
      'Name',
      'Affiliation',
      'User Type',
      'Email'
    ]
  end
  def csv_row_values
    [
      name,
      affiliation,
      user_type,
      email
    ]
  end

  def admin?
    self.admin
  end
end
