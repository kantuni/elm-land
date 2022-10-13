# Elm Land

[![Npm package version](https://badgen.net/npm/v/elm-land)](https://npmjs.com/package/elm-land) [![elm-land](https://github.com/elm-land/elm-land/actions/workflows/node.js.yml/badge.svg?)](https://github.com/elm-land/elm-land/actions/workflows/node.js.yml) [![BSD-3 Clause](https://img.shields.io/github/license/elm-land/elm-land)](https://github.com/elm-land/elm-land/blob/main/LICENSE)

[![Discord](https://badgen.net/badge/icon/discord?icon=discord&label&color=7289da)](https://join.elm.land) [![Twitter](https://badgen.net/badge/icon/twitter?icon=twitter&label&color=00acee)](https://twitter.com/elmland_) [![GitHub](https://badgen.net/badge/icon/github?icon=github&label&color=4078c0)](https://www.github.com/elm-land/elm-land) 

[![Elm Land: Reliable web apps for everyone](https://github.com/elm-land/elm-land/raw/main/elm-land-banner.jpg)](https://elm.land)


## Welcome to our repo!

The code for this GitHub project is broken down into smaller projects:

- __[elm-land](./projects/cli/)__ - The CLI tool, available at [npmjs.org/elm-land](https://npmjs.org/elm-land)
- __[@elm-land/www](./docs/)__ - The official website, available at [elm.land](https://elm.land)

### Plugins

The Elm Land CLI will come with optional plugins for making web apps, designed to fit really well together!

- __[@elm-land/graphql](./projects/graphql/)__ - The plugin that converts GraphQL files into Elm code
- __[@elm-land/ui](./projects/ui/)__ - The plugin that generates CSS and Elm code for your design system


### Tooling

This repo also includes a few tooling projects, separated out for anyone else making tooling for Elm:

- __[@elm-land/elm-error-json](./projects/tooling/elm-error-json/)__ - Render the Elm compiler's JSON error output as full-color HTML or colored ASCII terminal output

- __[@elm-land/codegen](./projects/tooling/codegen/)__ - a lightweight codegen library used internally by the Elm Land CLI