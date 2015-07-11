# == Schema Information
#
# Table name: changesets
#
#  id         :integer          not null, primary key
#  notes      :text
#  applied    :boolean
#  applied_at :datetime
#  created_at :datetime
#  updated_at :datetime
#

class ChangesetSerializer < ApplicationSerializer
  attributes :id,
             :notes,
             :applied,
             :applied_at,
             :created_at,
             :updated_at,
             :payload
  
   def payload
     {changes: object.change_payloads.map {|x| x.payload_as_ruby_hash[:changes]}}
   end

end
