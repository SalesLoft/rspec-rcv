# Purpose

The purpose of this gem is to provide a way to export the results of rspec tests to disk. In this way, a controller test can output the response body of the request, and then a front-end test can read that file in order to have predictable and maintainable front-end fixtures.

This gem currently only applies to the rspec testing framework.

# Usage

The gem is require'd in the rspec loading script, and will take effect from there by using the "fixture" option. For example, the following test would record response.body to spec/fixtures/widgets/index.json"

```ruby
describe "GET index" do
  it "is successful", fixture: "widgets/index.json" do
    get :index
    expect(response).to be_success
  end
end
```

The test itself does not need to do anything different, it is all in configuration.

If the file already exists, and the new content is not identical, the test will fail with a message indicating that this happened. This will prevent surprises from happening, and can be turned off in a configuration variable.

# Lifecycle

The result of the exportable variable is captured at the end of the test, after everything else has run. Because this is an
outer `after(:each)`, it will run after all of the other `after` blocks in the suite. This means you can't use the output of
the file in an after block (not that you should need to). See the spec suite here to understand how you *could* use the output of
the file in the spec suite.

# Configuration Options

The following options are available to override, as well as their default values:

```ruby
config.exportable_proc = Proc.new { response.body }
config.compare_with = Proc.new { |existing, new| existing == new }
config.export_with = Proc.new do |hash|
                               begin
                                 hash[:data] = JSON.parse(hash[:data])
                               rescue JSON::ParserError
                               end
                               JSON.pretty_generate(hash)
                             end
config.base_path = nil
config.fail_on_changed_output = true
```

`exportable_proc`, `compare_with`, `export_with` must implement `.call`. For `exportable_proc`, the result will be written to disk
and should be a String. For `compare_with`, the proc should return true when existing and new are considered equal. For `export_with`
a hash will be passed in and the result will be a String written to disk.

`export_with` by default tries to take hash[:data] (a string) and JSON parse it. If it isn't successful, that is fine and hash[:data] isn't
changed. If it is JSON, then the pretty print will work more optimally.

# What about fields that change everytime I run the specs?

This is why you can override `compare_with`. For instance, here is a configuration to ignore `id, created_at, updated_at` in a Rails app:

```ruby
RSpecRcv.configure do |config|
  config.configure_rspec_metadata!

  filters = [:id, :created_at, :updated_at]
  config.compare_with = lambda do |existing, new|
    existing = JSON.parse(existing)
    new = JSON.parse(new)

    existing.except(*filters) != new.except(*filters)
  end
end
```
