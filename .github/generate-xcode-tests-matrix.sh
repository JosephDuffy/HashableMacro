#!/usr/bin/env sh

set -e

platforms='["macOS","iOS","tvOS","watchOS","macCatalyst","visionOS"]'

includes='[
  {"os":"macos-14","xcode":"15.1"},
  {"os":"macos-14","xcode":"15.3"},
  {"os":"macos-15","xcode":"16.0"},
  {"os":"macos-15","xcode":"16.3"},
  {"os":"macos-26","xcode":"26.0.1"}
]'

jq --null-input \
  --argjson platforms "$platforms" \
  --argjson includes "$includes" \
  '
  reduce $includes[] as $inc (
    [];
    . + [
      $platforms[]
      | {
          platform: .,
          os: $inc.os,
          xcode: $inc.xcode
        }
      | select(.platform != "visionOS" or .xcode != "15.1")
    ]
  )
  '
