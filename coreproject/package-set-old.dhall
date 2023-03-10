let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.7.3-20221102/package-set.dhall sha256:9c989bdc496cf03b7d2b976d5bf547cfc6125f8d9bb2ed784815191bd518a7b9
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let additions = [
  { name = "hash"
  , version = "v0.1.1"
  , repo = "https://github.com/aviate-labs/hash.mo"
  , dependencies = [ "base" ] : List Text
  },
  { name = "array"
  , version = "v0.2.1"
  , repo = "https://github.com/aviate-labs/array.mo"
  , dependencies = [ "base" ] : List Text
  },
  { name = "crypto"
  , version = "v0.3.1"
  , repo = "https://github.com/aviate-labs/crypto.mo"
  , dependencies = [ "base", "encoding"] : List Text
  },
  { name = "encoding"
  , version = "v0.4.1"
  , repo = "https://github.com/aviate-labs/encoding.mo"
  , dependencies = [ "base", "array"] : List Text
  },
] : List Package

let
  {- This is where you can override existing packages in the package-set

     For example, if you wanted to use version `v2.0.0` of the foo library:
     let overrides = [
         { name = "foo"
         , version = "v2.0.0"
         , repo = "https://github.com/bar/foo"
         , dependencies = [] : List Text
         }
     ]
  -}
  overrides =
    [] : List Package

in  upstream # additions # overrides
