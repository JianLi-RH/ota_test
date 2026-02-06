#!/bin/sh

curl -s 'https://api.openshift.com/api/upgrades_info/graph?arch=amd64&channel=candidate-4.21&version=4.20.0-rc.2' | jq '
  (.nodes | with_entries(.key |= tostring)) as $nodes_by_index |
  (
    [
      .edges[] |
      select($nodes_by_index[(.[0] | tostring)].version == "4.20.0-rc.2")[1] |
      tostring |
      $nodes_by_index[.].version
    ]
  ) as $edges |
  (
    [
      .conditionalEdges[] |
      .risks as $r |
      .edges[] |
      select(.from == "4.20.0-rc.2") |
      .to as $to |
      {to: $to, risks: ([$r[] | .name])}
    ]
  ) as $conditionalEdges |
  {
    edges: $edges,
    conditionalEdges: $conditionalEdges
  }'
