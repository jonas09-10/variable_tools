# Variable Database Tools

A SketchUp Ruby extension for managing variable data and generating geometry. The source supports SketchUp 2019 and Ruby 2.5; the npm tools are used only for development and packaging.

## Setup

Install Node.js 18 or newer and Ruby (Ruby 2.5 is recommended for checking the oldest supported syntax), then run:

```sh
npm ci
npm test
npm run build
```

`npm test` checks the RBZ's contents and runs `ruby -c` on the extension's Ruby files. Ruby must be available on `PATH`. Syntax checks do not exercise SketchUp's API or prove compatibility with older Ruby versions when run using a newer interpreter; manually test behavior in SketchUp as well.

`npm run build` creates `dist/variable_tools.rbz`, containing the root loader and `variable_tools/` directory. In SketchUp, open Extension Manager and choose Install Extension to install that RBZ. The output and installed npm dependencies are ignored by Git.
