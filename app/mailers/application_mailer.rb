class ApplicationMailer < ActionMailer::Base
  default from: "transitland@mapzen.com" # TODO: change to a transit.land address
  layout 'mailer'
end
