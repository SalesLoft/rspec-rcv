# Purpose

The purpose of this gem is to provide a way to export the results of rspec tests to disk. In this way, a controller test can output the response body of the request, and then a front-end test can read that file in order to have predictable and maintainable front-end fixtures.

This gem currently only applies to the rspec testing framework.

# Usage

The gem is require'd in the rspec loading script, and will take effect from there by using the "export_fixture_to" option. For example, the following test would record response.body to spec/fixtures/widgets/index.json"

```ruby
describe "GET index" do
  it "is successful", export_fixture_to: "widgets/index.json" do
    get :index
    expect(response).to be_success
  end
end
```

The test itself does not need to do anything different, it is all in configuration.

If the file already exists, and the new content is not identical, the test will fail with a message indicating that this happened. This will prevent surprises from happening, and can be turned off in a configuration variable.

# Lifecycle

The result of the exportable variable is captured at the end of the test, after everything else has run.

# Configuration Options

The following options are available to override, as well as their default values:

```ruby
config.exportable_proc = Proc.new { response.body }
config.export_with = :to_json
config.base_path = nil
config.fail_on_changed_output = true
```
