let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.8.1-20230203/package-set.dhall
let Package = { name : Text, version : Text, repo : Text, dependencies : List Text }
let additions = [
  { name = "io"
  , repo = "https://github.com/aviate-labs/io.mo"
  , version = "v0.3.0"
  , dependencies = [ "base" ]
  },
  { name = "array"
  , repo = "https://github.com/aviate-labs/array.mo"
  , version = "v0.2.0"
  , dependencies = [ "base" ]
  },
  { name = "hash"
  , repo = "https://github.com/aviate-labs/hash.mo"
  , version = "v0.1.0"
  , dependencies = [ "base", "array" ]
  },
  { name = "encoding"
  , repo = "https://github.com/aviate-labs/encoding.mo"
  , version = "v0.3.2"
  , dependencies = [ "array", "base" ]
  },
  { name = "mutable-queue"
  , repo = "https://github.com/ninegua/mutable-queue.mo"
  , version = "2759a3b8d61acba560cb3791bc0ee730a6ea8485"
  , dependencies = [ "base" ]
  },
  { name = "accountid"
  , repo = "https://github.com/stephenandrews/motoko-accountid"
  , version = "06726b1625fea8870bc8c248d661b11a4ebfe7ae"
  , dependencies = [ "base" ]
  },
  { name = "ic-logger"
  , repo = "https://github.com/ninegua/ic-logger"
  , version = "95e06542158fc750be828081b57834062aa83357"
  , dependencies = [ "base" ]
  },
  { name = "rand"
  , repo = "https://github.com/aviate-labs/rand.mo"
  , version = "v0.2.1"
  , dependencies = [ "base" ]
  },
  { name = "ulid"
  , version = "v0.1.2"
  , repo = "https://github.com/aviate-labs/ulid.mo"
  , dependencies = [ "base", "encoding", "io" ]
  },
  { name = "numbers"
    , version = "v1.0.0"
    , repo = "https://github.com/gekctek/motoko_numbers"
    , dependencies = [] : List Text
  },
  { name = "icrc1"
    , version = "2ede9a69a6d9d15802d44dafb5403e767269e27b"
    , repo = "https://github.com/NatLabs/icrc1"
    , dependencies = [ "base" ] : List Text
  },
] : List Package
in  upstream # additions
