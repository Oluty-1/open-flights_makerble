# Build stage
FROM ruby:3.1-slim as builder

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install -y \
    build-essential \
    libpq-dev \
    nodejs \
    npm \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install yarn
RUN npm install -g yarn

WORKDIR /app

# Copy dependency files first (for better caching)
COPY Gemfile Gemfile.lock ./
COPY package.json yarn.lock ./

# Install Ruby dependencies
RUN bundle config set --local path 'vendor/bundle' && \
    bundle install --jobs 4 --retry 3

# Install JavaScript dependencies
RUN yarn install

# Copy application code
COPY . .

# Clean up build artifacts to reduce size
RUN rm -rf node_modules/.cache \
    tmp/cache \
    .git

# Runtime stage
FROM ruby:3.1-slim as production

# Install runtime dependencies (same as your working single-stage)
RUN apt-get update -qq && \
    apt-get install -y \
    postgresql-client \
    nodejs \
    npm \
    && npm install -g yarn \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the entire application from builder stage
COPY --from=builder /app /app

# Configure bundler to use the vendored gems
RUN bundle config set --local path 'vendor/bundle'

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]