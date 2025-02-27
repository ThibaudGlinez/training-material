name: "[Cron] Update news from Google Form"
on:
  workflow_dispatch:
  schedule:
    - cron: '21 10 * * *'
jobs:
  runner-job:
    runs-on: ubuntu-latest
    # Only run on main repo on and PRs that match the main repo.
    if: |
      github.repository == 'galaxyproject/training-material' &&
      (github.event_name != 'pull_request' ||
       github.event.pull_request.head.repo.full_name == github.repository)
    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 1

      # BEGIN Dependencies
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.0"
      - uses: actions/cache@v2
        with:
          path: |
            vendor/bundle
          key: ${{ runner.os }}-gems-${{ hashFiles('**/Gemfile.lock') }}
          restore-keys: |
            ${{ runner.os }}-gems-
      - name: Install dependencies
        run: |
          gem install bundler
          bundle config path vendor/bundle
          bundle install --jobs 4 --retry 3
          bundle pristine ffi
      # END Dependencies

      - name: Update Shortlinks
        id: generate
        run: |
          ruby bin/google-form-news.rb >> $GITHUB_OUTPUT

      - name: Create Pull Request
        # If it's not a Pull Request then commit any changes as a new PR.
        if: |
          github.event_name != 'pull_request' &&
          steps.generate.outputs.new_ids != ''
        uses: peter-evans/create-pull-request@v3
        with:
          title: Import news posts from Google Form
          branch-suffix: timestamp
          commit-message: New News Post!
          add-paths: news/_posts/
