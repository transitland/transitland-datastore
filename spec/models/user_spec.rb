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

describe User do
  let(:user) { create(:user) }

  it 'can be created' do
    expect(User.exists?(user.id)).to be true
  end

  it 'must have an e-mail address' do
    expect {
      create(:user, email: '')
    }.to raise_error ActiveRecord::RecordInvalid
  end

  it 'can author changesets' do
    changeset = create(:changeset, author: user)
    expect(changeset.author).to eq user
  end

  it 'if its email is changed, changesets associations are updated too' do
    create_list(:changeset, 5, author: user)
    create_list(:changeset, 2)
    expect(user.changesets.count).to eq 5
    user.update(email: 'new@example.com')
    expect(user.changesets.count).to eq 5
  end
end
