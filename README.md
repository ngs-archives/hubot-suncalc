hubot-suncalc
=============

[![Build Status][travis-badge]][travis]
[![npm-version][npm-badge]][npm]

A [Hubot] script that replies sunrise and sunset of the day for given location.

```
me > hubot sunrise Taipei
hubot > Sunrise in Taipei City, Taiwan is 5:24 AM.
me > hubot sunset Taipei
hubot > Sunset in Taipei City, Taiwan is 6:33 PM.
me > hubot moonphase
hubot > 🌔  55.97%
```

Commands
--------

```
hubot sunrise <location>
hubot sunset <location>
hubot moonphase
```

Installation
------------

1. Add `hubot-suncalc` to dependencies.

  ```bash
  npm install --save hubot-suncalc
  ```

2. Update `external-scripts.json`

  ```json
  ["hubot-suncalc"]
  ```

Configuration
-------------

```
HUBOT_GOOGLE_API_KEY
```

Grab yours from the [APIs console].

Author
------

[Atsushi Nagase]

License
-------

[MIT License]


[Hubot]: https://hubot.github.com/
[Atsushi Nagase]: http://ngs.io/
[MIT License]: LICENSE
[travis-badge]: https://travis-ci.org/ngs/hubot-suncalc.svg?branch=master
[npm-badge]: http://img.shields.io/npm/v/hubot-suncalc.svg
[travis]: https://travis-ci.org/ngs/hubot-suncalc
[npm]: https://www.npmjs.org/package/hubot-suncalc
[APIs console]: https://code.google.com/apis/console/?noredirect
