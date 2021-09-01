# views_coverage
ViewsCoverage is Minitest plugin for showing which views or partials was generated during tests. Plugin listening for [render notification from Rails framework](https://guides.rubyonrails.org/active_support_instrumentation.html#action-view) and save data from this event (path to view and how many times it was generated). 

## Installation
Add this line to your application's Gemfile:

```
gem 'views_coverage'
```

And then execute:
        
```
$ bundle
```

## Usage
__Warning: Plugin dont support parallel tests. If you want to use this plugin, set `parallelize(workers: 1)` or comment `parallelize` line in your `test_helper.rb`.__ 

Basic usage is run tests with `--views-coverage` flag:

```
rails test --views-coverage
```

or if you run system tests, this flag must be passed in TESTOPS:

```
rails test:system TESTOPTS="--views-coverage"
```

This command will generate following files:
* for unit tests - `views_coverage_result_unit_pretty.txt` and `views_coverage_result_unit.yml`
* for system tests - `views_coverage_result_system_pretty.txt` and `views_coverage_result_system.yml`

`*.txt` files are containing pretty printed coverage output.
`*.yml` files are containing coverage for "merge" mode (viz next paragraph).

### Merge results from multiple test runs
If you want to merge results from multiple test runs (for example from unit tests and system tests), you should pass `--views-coverage-mode=merge` when running tests:

```
rails test:system TESTOPTS="--views-coverage --views-coverage-mode=merge"
```

This mode load content of YML files and merge their results into `views_coverage_result_merged_pretty.txt` and `views_coverage_result_merged_pretty.yml` files.

## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/jchsoft/views_coverage. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the Contributor Covenant code of conduct.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct
Everyone interacting in the ViewsCoverage project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/jchsoft/views_coverage/blob/master/CODE_OF_CONDUCT.md).
