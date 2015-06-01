#!/usr/bin/env ruby

environment = ARGV[0]
ARGV[0] = nil

load Gem.bin_path('bundler', 'bundle')

require 'aws-sdk'

# staging env -> dev
if environment == 'staging'
  environment = 'dev'
end

config = {
  dev: {
    stack_id: "c268a326-fc6a-4d0b-a24d-686b0b87524e",
    layer_id: "e1e5395b-d38b-4dca-99ab-5724f38298aa",
    app_id: "37734730-4a4f-48cf-94b9-ca03e5cc4e98"
  },
  prod: {
    stack_id: "3c2c59ef-c407-474b-b6a1-5551397c0a51",
    layer_id: "be95fa2e-0630-4447-b6b1-6768a86d251c",
    app_id: "404c267b-a060-4871-977b-9948b7a2bc5d"
  }
}

# environment variables to deploy to dev stack are prefixed with STAGING
env_name = environment == 'dev' ? 'STAGING' : environment.upcase

client = Aws::OpsWorks::Client.new({
  region: 'us-east-1',
  access_key_id: ENV["#{env_name}_AWS_ACCESS_KEY_ID"],
  secret_access_key: ENV["#{env_name}_AWS_SECRET_ACCESS_KEY"]
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
