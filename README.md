# Purpose

The purpose of this gem is to provide a way to export the results of rspec tests to disk. In this way, a controller test can output the response body of the request, and then a front-end test can read that file in order to have predictable and maintainable front-end fixtures.

This gem currently only applies to the rspec testing framework.

# Usage

The gem is require'd in the rspec loading script, and will take effect from there by using the "fixture" option. For example, the following test would record response.body to spec/fixtures/widgets/index.json"

```ruby
describe "GET index" do
  it "is successful", rcv: {fixture: "spec/fixtures/widgets/index.json"} do
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

The following options are available to override, as well as important default values:

```ruby
config.exportable_proc = Proc.new { JSON.parse(response.body) }
config.compare_with # Deep ignoring comparison by default
config.codec = Codecs::PrettyJson.new
config.ignore_keys = []
config.base_path = nil
config.fail_on_changed_output = true
```

`exportable_proc`, `compare_with` must implement `.call`. For `exportable_proc`, the result will be written to disk
and should be a String. For `compare_with`, the proc should return true when existing and new are considered equal.

`exportable_proc` assumes JSON response by default, but could be override to allow for other types of responses.

`codec` must implement `export_with(hash)` and `decode_with(str)`. There is a PrettyJson and Yaml codec included in this gem,
and PrettyJson is the default as it can be directly consumed by javascript.

# What about fields that change everytime I run the specs?

There is an option called `ignore_keys` which will deep ignore keys that you don't want to cause spec change. For instance,
the following hashes would not trigger a change with `ignore_keys = [:id]`

```
{
  id: 1,
  deep: {
    id: 2,
    name: "Steve"
  }
}

{
  id: "DIFF",
  deep: {
    "id" => "DIFF,
    name: "Steve"
  }
}
```

but if the name changed from "Steve", then a change would be triggered.

If you want more configuration, you can override `compare_with`. For instance, here is a configuration to shallowly ignore 
`id, created_at, updated_at` in a Rails app:

```ruby
RSpecRcv.configure do |config|
  config.configure_rspec_metadata!

  filters = [:id, :created_at, :updated_at]
  config.compare_with = lambda do |existing, new|
    existing = ActiveSupport::HashWithIndifferentAccess.new(existing)
    new = ActiveSupport::HashWithIndifferentAccess.new(JSON.parse(new))

    existing.except(*filters) != new.except(*filters)
  end
end
```

# What happens when fields change that shouldn't?

You will get a diff of the output to your console. Here is an example:

![image](https://cloud.githubusercontent.com/assets/1231659/8729785/2a2aaa24-2bbb-11e5-90fe-99572a95ab7f.png)


