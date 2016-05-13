# == Schema Information
#
# Table name: issue_types
#
#  id          :integer          not null, primary key
#  type_name   :string
#  description :string
#  category    :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe IssueType, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
