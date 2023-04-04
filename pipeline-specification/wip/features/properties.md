- Property meta data definition
- Nested properties
- Lazy loading
# Overview

This document contains details on the features associated with the properties that 
are populated by flow elements.

# Value types

A property may return values of any type. However, there are certain types that are 
specifically expected and supported throughout the API.

The primary limitation is that it must be possible for these types to be represented 
in json data.

As such, the core types are:

- string
- boolean
- numeric (integer or floating point)
- array of strings

In addition, there are a couple of types that are supported through additions in 
json encode/decode logic:

- javascript - See [the javascript type](#the-javascript-type) below
- array of key-value-pair collections - Used in scenarios where we want to return 
  multiple aspect data instances. (For example, TAC lookup)

## The javascript type

The javascript type is a custom type that simply represents a string.
It is used to identify values that contain JavaScript snippets that are intended 
to be executed on the client device.

# Null values

Property values must be capable of having 'no value'

Where 'no value' is used, attempting to access the value should throw an 
error/exception with a customizable message explaining why the value is not set. 

# Property meta data

# Lazy loading

This feature is specific to properties populated by engines (rather than all flow 
elements).