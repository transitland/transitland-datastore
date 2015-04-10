#!/usr/bin/env ruby

environment = ARGV[0]
ARGV[0] = nil

load Gem.bin_path('bundler', 'bundle')

require 'aws-sdk'

config = {
  staging: {
    stack_id: "c268a326-fc6a-4d0b-a24d-686b0b87524e",
    layer_id: "677ecf26-eb45-4e07-a0ca-590fe602fd4c",
    app_id: "ffd516b0-e1b4-4cb6-8c52-d06de7b0c822"
  }
}

client = Aws::OpsWorks::Client.new({
  region: 'us-east-1',
  access_key_id: ENV["#{environment.upcase}_AWS_ACCESS_KEY_ID"],
  secret_access_key: ENV["#{environment.upcase}_AWS_SECRET_ACCESS_KEY"]
  )
})

# get the instances we want to deploy to
instances = client.describe_instances(
  layer_id: config[environment.to_sym][:layer_id]
)

instance_ids = instances[:instances].map(&:instance_id)

deployment = client.create_deployment(
  stack_id: config[environment.to_sym][:stack_id],
  app_id: config[environment.to_sym][:app_id],
  instance_ids: instance_ids,
  command: {
    name: "deploy",
    args: { "migrate" => ["true"] }
  },
  comment: "Deploying build from circleci: #{ENV['CIRCLE_BUILD_NUM']} sha: #{ENV['CIRCLE_SHA1']} #{ENV['CIRCLE_COMPARE_URL']}"
)

timeout = 60 * 10
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
