---
layout: post
title: "tfanalyze"
---

I work on relatively large Terraform states. Some of those Terraform states hold a lot of resources that can handle
deletion when something goes wrong – most don't.

Sometimes I'll have a changeset that produces big Terraform plans. Going through changesets with 40 modified resources
and 10 deletions, when some of those resources are mission-critical databases, can be somewhat anxiety-inducing.

To get a better overview over what resources are being changed, I wrote `tfanalyze`. It's a very minimal Python script
that parses your Terraform plans and gives you a summary.

> Disclaimer: This post is about Terraform, because that is what I work with. I am relatively certain it applies
> to OpenTofu as well. If somebody wants to try out `tfanalyze` against an OpenTofu project, feel free and let me
> know how it goes!

A typical usage of `tfanalyze` looks something like this:

```shell
$ terraform plan -out plan.tfplan
$ tfanalyze plan.tfplan
  DESTROY grafana_data_source.grafana_amazon_prometheus_datasource
  DESTROY grafana_data_source.loki["team-a"]
  DESTROY grafana_data_source.loki["team-b"]
  DESTROY grafana_data_source.loki_admin
  DESTROY grafana_data_source_permission.loki_admin_logs_read
  DESTROY grafana_data_source_permission.loki_team_logs_read["team-a"]
  DESTROY grafana_data_source_permission.loki_team_logs_read["team-b"]
  UPDATE grafana_folder.infrastructure
    title: infrastructure -> infra
```

Admittedly, this isn't the most complex example, but it gets the point across.

## Installation

Of course, the main point of this article is that I think this is a neat tool that others could benefit from.
If it can help prevent just a single incident, I'd be happy. `tfanalyze` is available from pyPI and can be installed
via `uv`, `pipx` or any other package manager:

```shell
uv tool install tfanalyze
```

```shell
pipx install tfanalyze
```

## How it works

`tfanalyze` parses a plan as JSON and then performs any analysis on it. There's no streaming, so don't input any plans
several hundreds of megabytes in size! Although, to be fair, you'll have a whole range of other problems if that's your
use-case.

```python
output = subprocess.run(
    ["terraform", "show", "-json", plan], check=True, capture_output=True
)
return json.loads(output.stdout)
```

The raw JSON gets parsed into a `dataclass`, which is used as the basis for further operations.

```python
@dataclass
class Change:
    """
    Represents a subset of a .resource_changes[] entry from a Terraform plan JSON.
    """

    address: str
    type: str
    name: str
    change_action: ChangeAction
    properties_before: dict
    properties_after: dict


def from_entry(entry: dict) -> Change:
    return Change(
        address=entry["address"],
        type=entry["type"],
        name=entry["name"],
        change_action=ChangeAction.from_entry(entry),
        properties_before=entry["change"]["before"],
        properties_after=entry["change"]["after"],
    )
```

All changes get printed:

```python
def _summarize(
        changes: list[Change]
):
    for change in changes:
        secho(change.change_action.name, fg=change.change_action.value, nl=False)
        secho(f" {change.address}")
```

And honestly, beyond that, there's not a lot here. There's some filtering, and some command-line flags that the
application accepts that I haven't gotten into, but nothing major. `tfanalyze` runs with `click`, so if you're not
familiar with `click` and want to get into developing CLI applications in Python, check it out!

## Caveats

Right now, updates do not get rendered very gracefully. Larger updates to various attributes won't look particularly
pleasing, and their informational content may be limited. If there's any interest in the tool, I might pick that up.

---

You can check out the source code over at [twaslowski/tfanalyze](https://github.com/twaslowski/tfanalyze).