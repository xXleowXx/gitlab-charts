# Writing RSpec tests for charts

The following are notes and conventions used for creating RSpec tests for the
GitLab chart.

## Filtering RSpec tests

To aid in development it is possible to filter which tests are executed by
adding the `:focus` tag to one or more tests. With the `:focus` tag _only_
tests that have been specifically tagged will be run. This allows quick
development and testing of new code without having to wait for all the RSpec
tests to execute. The following is an example of a test that has been tagged
with`:focus`.

```ruby
describe 'some feature' do
  it 'generates output', :focus => true do
    ...
  end
end
```

The `:focus` tag can be added to `describe`, `context` or `it` blocks which
allows a test or a group of tests to be executed.

## Generating YAML from the chart

Much of the testing of the chart is that it generates the correct YAML
structure given a number of [chart inputs](#chart-inputs). This is done using
the HelmTemplate class as in the following:

```ruby
obj = HelmTemplate.new(values)
```

The resulting `obj` encodes the YAML documents returned by the `helm template`
command indexed by the [Kubernetes object `kind`](https://kubernetes.io/docs/concepts/#kubernetes-objects) and the object name (`metadata.name`). This indexed
valued is used by most of the methods to locate values within the YAML.

For example:

```ruby
obj.dig('ConfigMap/test-gitaly', 'data', 'config.toml.erb')
```

This will return the contents of the `config.toml.erb` file contained in the
`test-gitaly` ConfigMap.

NOTE:
Using the `HelmTemplate` class will always use the release name of "test"
when executing the `helm template` command.

## Chart inputs

The input parameter to the `HelmTemplate` class constructor is a dictionary
of values that represents the `values.yaml` that is used on the Helm command
line. This dictionary mirrors the YAML structure of the `values.yaml` file.

```ruby
describe 'some feature' do
  let(:default_values) do
    YAML.safe_load(%(
      certmanager-issuer:
        email:
          test@example.com
    ))
  end

  describe 'global.feature.enabled' do
    let(:values) do
      YAML.safe_load(%(
        global:
          feature:
            enabled: true
      )).deep_merge(default_values)
    end

    ...
  end
end
```

The above snippet demonstrates a common pattern of setting a number of default
values that are common across multiple tests that are then merged into the
final values that are used in the `HelmTemplate` constructor for a specific
set of tests.

### Using property merge patterns

Throughout the RSpec of this project, you will find different forms of `merge`. There are a few guidelines and considerations to take into account when choosing which to make use of.

Helm merges / coalesces configuration properties via [coalesceValues function](https://github.com/helm/helm/blob/a499b4b179307c267bdf3ec49b880e3dbd2a5591/pkg/chartutil/coalesce.go#L145-L148), which has some distinctly different behaviors to `deep_merge` as implemented here. We continue to refine how this functions within our RSpec.

Ruby's native `Hash.merge` will _replace_ keys in the destination, it will not deeply walk an
object. This means that all properties under a tree will be removed if the source has a matching entry.

```plaintext
2.7.2 :002 > require 'yaml'
 => true 
2.7.2 :003"> example = YAML.safe_load(%(
2.7.2 :004">   a:
2.7.2 :005">     b: 1
2.7.2 :006">     c: [ 1, 2, 3]
2.7.2 :007 >  ))
 => {"a"=>{"b"=>1, "c"=>[1, 2, 3]}} 
2.7.2 :008"> source = YAML.safe_load(%(
2.7.2 :009">   a:
2.7.2 :010">     d: "whee"
2.7.2 :011 >  ))
 => {"a"=>{"d"=>"whee"}} 
2.7.2 :012 > example.merge(source)
 => {"a"=>{"d"=>"whee"}}
```

In an attempt to address, this we've been using the [hash-deep-merge](https://rubygems.org/gems/hash-deep-merge/) gem to perform naive deep merge of YAML documents. When _adding_ properites, this has worked well. The drawback is that this does not provide a means to cause overwrite of nested structures.

```plaintext
2.7.2 :013 > require 'hash_deep_merge'
2.7.2 :014 > example = {"a"=>{"b"=>1, "c"=>[1, 2, 3]}}
 => {"a"=>{"b"=>1, "c"=>[1, 2, 3]}} 
2.7.2 :015 > source = {"a"=>{"b"=> 2, "d"=>"whee"}} 
 => {"a"=>{"b"=>2, "d"=>"whee"}}
2.7.2 :016 > example.deep_merge(source)
 => {"a"=>{"b"=>2, "c"=>[1, 2, 3], "d"=>"whee"}}
```

The problem of the difference between `deep_merge` and `coasleceValues` within Helm can be seen with the below example. In Helm, the merge of `removeSecurityContext` would result in `securityContext` being empty. The desired behavior is the equavilent of [`merge.WithOverride`](https://github.com/imdario/mergo#usage) from `github.com/imdario/mergo` Go module as used within Helm and Sprig.

```plaintext
2.7.2 :049"> securityContext = YAML.safe_load(%(
2.7.2 :050">   gitlab:
2.7.2 :051">     gitaly:
2.7.2 :052">       securityContext:
2.7.2 :053">         fsGroup: 1000
2.7.2 :054">         user:    1000
2.7.2 :055 >             ))
 => {"gitlab"=>{"gitaly"=>{"securityContext"=>{"fsGroup"=>1000, "user"=>1000}}}} 
2.7.2 :056"> noUser = YAML.safe_load(%(
2.7.2 :057">   gitlab:
2.7.2 :058">     gitaly:
2.7.2 :059">       securityContext:
2.7.2 :060">         user: null
2.7.2 :061 >           ))
 => {"gitlab"=>{"gitaly"=>{"securityContext"=>{"user"=>nil}}}}
2.7.2 :062"> removeSecurityContext = YAML.safe_load(%(
2.7.2 :063">   gitlab:
2.7.2 :064">     gitaly:
2.7.2 :065">       securityContext: {}
2.7.2 :066 >         ))
2.7.2 :067 > securityContext.deep_merge(removeSecurityContext)
 => {"gitlab"=>{"gitaly"=>{"securityContext"=>{"fsGroup"=>1000, "user"=>1000}}}}
```

General guidelines:

1. Be aware of and wary of the behavior of `Hash.merge`.
1. Be aware of and wary of the behavior of `Hash.deep_merge` offered by `hash-deep-merge` gem.
1. When you need to overwrite a specific key, do so explicitly.
1. Do not use imperative forms (`merge!`) unless expressly needed. When doing so, comment why.

## Testing the results

The `HelmTemplate` object has a number of methods that assist with writing
RSpec tests. The following are a summary of the available methods.

- `.exit_code()`

This returns the exit code of the `helm template` command used to create the
YAML documents that instantiates the chart in the Kubernetes cluster. A
successful completion of the `helm template` will return an exit code of 0.

- `.dig(key, ...)`

Walk down the YAML document returned by the `HelmTemplate` instance and
return the value residing at the last key. If no value is found, then `nil`
is returned.

- `.labels(item)`

Return a hash of the labels for the specified object.

- `.template_labels(item)`

Return a hash of the labels used in the template structure for the specified
object. The specified object should be a Deployment, StatefulSet or a CronJob
object.

- `.annotations(item)`

Return a has of the annotations for the specified object.

- `.template_annotations(item)`

Return a hash of the annotations used in the template structure for the
specified object. The specified object should be a Deployment, StatefulSet
or a CronJob object.

- `.volumes(item)`

Return an array of all the volumes for the specified deployment object. The
returned array is a direct copy of the `volumes` key from the deployment
object.

- `.find_volume(item, volume_name)`

Return a dictionary of the specified volume from the specified deployment
object.

- `.projected_volume_sources(item, mount_name)`

Return an array of sources for the specified projected volume. The returned
array has the following structure:

```yaml
- secret:
    name: test-rails-secret
    items:
     - key: secrets.yml
       path: rails-secrets/secrets.yml
```

- `.stderr()`

Return the STDERR output from the execution of `helm template` command.

- `.values()`

Return a dictionary of all values that were used in the execution of the
`helm template` command.

## Tests that require a Kubernetes cluster

The majority of the RSpec tests execute `helm template` and then analyze
the generated YAML for the correct structures given the feature being
tested. Occasionally an RSpec test requires access to a Kubernetes cluster
with the GitLab Helm chart deployed to it. Tests that interact with the
chart deployed in a Kubernetes cluster should be placed in the `features`
directory.

If the RSpec tests are being executed and a Kubernetes cluster is not
available, then the tests in the `features` directory will be skipped. At
the start of an RSpec run `kubectl get nodes` will be checked for results
and if it returns successfully the tests in the `features` directory will
be included.
