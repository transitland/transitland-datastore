#!/usr/bin/env ruby

environment = ARGV[0]
ARGV[0] = nil

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../DeployGemfile', __FILE__)
load Gem.bin_path('bundler', 'bundle')

require 'aws-sdk'

AWS.config(
  access_key_id: ENV["#{environment.upcase}_AWS_ACCESS_KEY_ID"],
  secret_access_key: ENV["#{environment.upcase}_AWS_SECRET_ACCESS_KEY"]
)

config = {
  staging: {
    stack_id: "db959bc5-7818-4a1c-8b9f-04d26ce6dae5",
    layer_id: "c1f6b265-27b0-4bc6-b8eb-bb4d72a80179",
    app_id: "914e9d2b-8656-4780-bb92-998a78e3c0ed"
  }
}

client = AWS::OpsWorks::Client.new

instance_arr = []
i[:instances].each do |instance|
  instance.values_at(:instance_id).each do |v|
    instance_arr.push(v)
  end
end

deployment = client.create_deployment(
  stack_id: config[environment.to_sym][:stack_id],
  app_id: config[environment.to_sym][:app_id],
  instance_ids: instance_arr,
  command: {
    name: "deploy"
  },
  comment: "Deploying build from circleci: #{ENV['CIRCLE_BUILD_NUM']} sha: #{ENV['CIRCLE_SHA1']} #{ENV['CIRCLE_COMPARE_URL']}"
)

timeout = 60 * 5
time_start = Time.now.utc
time_passed = 0
success = false

process = ["\\", "|", "/", "-"]
i = 0
while !success
  desc = client.describe_deployments(options = {:deployment_ids => [deployment[:deployment_id]]})
  success = desc[:deployments][0][:status] == "successful"
  time_passed = Time.now.utc - time_start 
  if i >= process.length - 1
    i = 0
  else
    i+=1
  end
  print "\r"
  print "Deploying: #{process[i]} status: #{desc[:deployments][0][:status]} timeout: #{timeout} -- time passed: #{time_passed}"
  if timeout < time_passed
    exit 1
  end
  sleep 4
end

exit 0
