source virtualenv/bin/activate
eval $(aws --profile ${TRANSITLAND_AWS_PROFILE} ecr get-login --no-include-email --region ${TRANSITLAND_AWS_REGION})

# Check specs
set -e
bundle exec rspec

# Build and push image
docker build -t transitland-datastore .
docker tag transitland-datastore:latest ${TRANSITLAND_AWS_ECR}/transitland-datastore:latest
docker push ${TRANSITLAND_AWS_ECR}/transitland-datastore:latest
