# == Schema Information
#
# Table name: issues
#
#  id                           :integer          not null, primary key
#  feed_version_id              :integer
#  created_by_changeset_id      :integer
#  resolved_by_changeset_id     :integer
#  description                  :string
#  block_import_changeset_apply :boolean          default(FALSE)
#  created_at                   :datetime
#  updated_at                   :datetime
#

require 'rails_helper'

RSpec.describe Issue, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
