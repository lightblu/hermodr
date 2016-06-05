# Hermodr [![Build Status](https://travis-ci.org/lightblu/hermodr.svg)](https://travis-ci.org/lightblu/hermodr)

[Hermóðr](https://en.wikipedia.org/wiki/Herm%C3%B3%C3%B0r) the Brave (Old Norse "war-spirit", anglicized as Hermod) is a figure in Norse mythology, a son of the god Odin. He is often considered the messenger of the gods (*and in this case the god is [Prometheus](prometheus.io)*).

At the moment, this project does nothing but proxy few MongoDB metrics as Prometheus
scrapable output, and it is unlikely that this will grow much more.

**Note:** This is a toy project with the purpose to relearn Haskell and have a look into
automated GitHub -> travisCI -> Docker Hub build chain. However you came here, you should
really have a look into the more professional
[offical and third-party exporters](https://prometheus.io/docs/instrumenting/exporters/).

I recommend
[Telegraf](https://influxdata.com/time-series-platform/telegraf/)
which is part of the influxdata stack, but offers a multitude of configurable
input and output plugins and works damn well with Prometheus.
This is also no real Prometheus client but just directly proxying metrics,
if you are looking for that head to the
[Prometheus package on Hackage](https://hackage.haskell.org/package/prometheus)
[(src)](https://github.com/LukeHoersten/prometheus).
There is also the [prometheus-haskell](https://github.com/fimad/prometheus-haskell) package.


Notes
=====

### Cabal workflow

    cabal sandbox init
    cabal sandbox add-source /opt/prometheus-0.3.2.1
    cabal install --dependencies-only
    cabal build
    cabal repl
    cabal sandbox delete

### Multiline mode in ghci

    *Main> :set +m

### Extensions in ghci

    *Main> :set -XOverloadedStrings
    *Main> :set -XExtendedDefaultRules

### Determine type in ghci

    .> :t "Oh, what's this?"
    "Oh, what's this?" :: Data.String.IsString a => a

### Reload in cabal repl

    > :r

### MongoDB in repl

    :set -XOverloadedStrings
    :set -XExtendedDefaultRules
    :set +m

    import Database.MongoDB
    import Database.MongoDB.Admin

    pipe <- connect $ host "172.17.0.1"
    let run act = access pipe master "test" act
    let replSetGetStatus = useDb admin $ runCommand ["replSetGetStatus" =: (1 :: Int)]
    r <- run replSetGetStatus
    r !? "ok"
    valueAt "ok" r

### Some repl playing

    d <- fetchMongoServerStatus
    let v = valueAt "host" d
    let m1 = valueAt "uptimeMillis" d
    let m2 = valueAt "uptimeEstimate" d
    valueToBuilder (valueAt "network" d)

    promBuilder ["host"] "m" d
    promBuilder ["network","bytesOut"] "m" d


    promBuilder ["uptimeMillis"] "mongo" [("host","test")] d



Links
=====

- Haskell

  - [Haskell in 5 steps](https://wiki.haskell.org/Haskell_in_5_steps)
  - [Typeclassopedia](https://wiki.haskell.org/Typeclassopedia)
  - [List of Haskell web servers](https://wiki.haskell.org/Web/Servers)
  - [Control.Concurrent - concurrency extension](https://downloads.haskell.org/~ghc/7.0.3/docs/html/libraries/base-4.3.1.0/Control-Concurrent.html)
  - [Haskell Indentation](https://en.wikibooks.org/wiki/Haskell/Indentation)
  - [Basic Syntax Extensions](https://www.schoolofhaskell.com/school/to-infinity-and-beyond/pick-of-the-week/guide-to-ghc-extensions/basic-syntax-extensions#overloadedstrings)
  - [Haskell for multicores](https://wiki.haskell.org/Haskell_for_multicores)
  - [Newtype](https://wiki.haskell.org/Newtype)
  - [Overloaded Strings Extension](https://ocharles.org.uk/blog/posts/2014-12-17-overloaded-strings.html)
  - [Pattern guards - Haskell 2010 changes the syntax for guards by replacing the use of a single condition with a list of qualifiers.](https://wiki.haskell.org/Pattern_guard)

  - [Learn you a Haskell](http://learnyouahaskell.com/)
    - [Input and Output](http://learnyouahaskell.com/input-and-output)
    - [Making your own types and typeclasses](http://learnyouahaskell.com/making-our-own-types-and-typeclasses)

- Haskell package related

  - [Data.ByteString.Builder](https://hackage.haskell.org/package/bytestring-0.10.8.1/docs/Data-ByteString-Builder.html)
  - [Data.Text](https://hackage.haskell.org/package/text-1.2.2.1/docs/Data-Text.html)
  - [Wai](http://hackage.haskell.org/package/wai)
  - [Network.Wai.Internal source](https://hackage.haskell.org/package/wai-3.0.3.0/docs/src/Network-Wai-Internal.html)

- Cabal

  - [Cabal guide](http://katychuang.com/cabal-guide/)
  - [Cabal-Install](https://wiki.haskell.org/Cabal-Install#Installing_a_package)
  - [An Introduction to Cabal sandboxes](http://coldwa.st/e/blog/2013-08-20-Cabal-sandbox.html)
  - [Cabal User Guide: Developing Cabal packages](https://www.haskell.org/cabal/users-guide/developing-packages.html)

- Haskell, building

  - [GHC on Alpine](https://github.com/mitchty/alpine-linux-ghc-bootstrap/tree/master)
  - [Porting GHC to Alpine](https://wiki.alpinelinux.org/wiki/Porting_GHC_to_Alpine)
  - [Small Haskell program compiled with GHC into huge binary](http://stackoverflow.com/questions/6115459/small-haskell-program-compiled-with-ghc-into-huge-binary)
  - [Haskell: unnecessary binary growth with module imports](http://stackoverflow.com/questions/9198112/haskell-unnecessary-binary-growth-with-module-imports/9198223#9198223)

        ghc-options:         -threaded -rtsopts -with-rtsopts=-N -O2 -split-objs -dynamic

- Mongo

  - [Haskell MongoDB driver](https://github.com/mongodb-haskell/mongodb)
  - [Haskell MongoDB driver Example](https://github.com/mongodb-haskell/mongodb/blob/master/doc/Example.hs)
  - [Example.hs](https://github.com/mongodb-haskell/mongodb/blob/master/doc/Example.hs)
  - [Tutorial](https://github.com/TonyGen/mongoDB-haskell/blob/master/doc/tutorial.md)
  - [Database.MongoDB.Admin hs](https://github.com/mongodb-haskell/mongodb/blob/master/Database/MongoDB/Admin.hs)
  - [Bson on github](https://github.com/mongodb-haskell/bson)
  - [Another tutorial](http://stevepowell.ca/mongo-haskell.html)


- Other
  - [Prometheus Intro](https://groob.io/posts/prometheus-intro/)
  - [Arrow Anti Pattern](http://www.c2.com/cgi/wiki?ArrowAntiPattern)
  - [Travis CI - Docker](https://docs.travis-ci.com/user/docker/)
  - [Tarvis CI - Docker Tutorial](https://sebest.github.io/post/using-travis-ci-to-build-docker-images/)

  - [(GitHub-Flavored) Markdown Editor](https://jbt.github.io/markdown-editor)
  - [What are the differences between open-source licenses?](http://zgp.org/~dmarti/qanda/what-are-the-differences-between-open-source-licenses/)
