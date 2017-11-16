# dslink-dart-mongodb-controller

[![Build Status](https://travis-ci.org/IOT-DSA/dslink-dart-mongodb-controller.svg?branch=master)](https://travis-ci.org/IOT-DSA/dslink-dart-mongodb-controller)

## Overview
This DSLink has for goal to provide basic functionality over MongoDB instances.

## Features

- [x] Find many
- [x] Find many streaming
- [ ] Find one
- [x] Fields projection in finds
- [ ] Distinct
- [ ] Insert

## Usage

- Add a connection from the root node
- Invoke Actions on your collections

### Find/FindStream

#### Selector
Used to filter results. Expects a JSON map. By default, an empty map keeps everything.

_keeps records having the field "name" with the value "joel"_ : `{"name": "joel"}`

#### Fields
Projects the fields in the query. Expects a JSON array of Strings. By default an empty array projects all fields.

_example_ : `["name", "age"]`

#### Limit/Skip
