#!/usr/bin/env sh

set -e

platforms='["macOS","iOS","tvOS","watchOS","macCatalyst","visionOS"]'

includes='[
  {"os":"macos-14", "xcode":"15.2", "swift": "5.9"},
  {"os":"macos-14", "xcode":"15.3", "swift": "5.10"},
  {"os":"macos-15", "xcode":"16.0", "swift": "6.0"},
  {"os":"macos-15", "xcode":"16.3", "swift": "6.1"},
  {"os":"macos-26", "xcode":"26.0.1", "swift": "6.2"}
]'

jq --null-input \
  --compact-output \
  --argjson platforms "$platforms" \
  --argjson includes "$includes" \
  '
  {
    include: (
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
    )
  }
  '
