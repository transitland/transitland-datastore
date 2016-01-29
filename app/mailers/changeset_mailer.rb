class ChangesetMailer < ApplicationMailer
  def creation(changeset_id)
    @changeset = Changeset.find(changeset_id)
    mail to: @changeset.user.email,
         subject: "Hello from Transitland. We've received your contribution!"
  end

  def application(changeset_id)
    @changeset = Changeset.find(changeset_id)
    mail to: @changeset.user.email,
         subject: "Hello from Transitland. We've added your contribution!"
  end
end
