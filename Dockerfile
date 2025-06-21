# Use official Ruby image
FROM ruby:3.1

# Install dependencies
RUN apt-get update -qq && apt-get install -y nodejs yarn postgresql-client

# Set working directory
WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy package.json and install npm packages
COPY package.json yarn.lock ./
RUN yarn install

# Copy application code
COPY . .

# Precompile assets
RUN bundle exec rake assets:precompile


# Runtime stage
FROM ruby:3.1-slim

RUN apt-get update && apt-get install -y postgresql-client && apt-get clean

WORKDIR /app

COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Expose port
EXPOSE 3000

# Start the server
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]
