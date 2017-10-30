
## Development & testing

Install dependencies, create a test database and schema, and then run the test
suite:

```
bundle install
createdb rocket-rides-log-test
psql rocket-rides-log-test < schema.sql
bundle exec rspec spec/
```
