# Variable Database Tools

A SketchUp Ruby extension for managing variable data and generating geometry. The source supports SketchUp 2019 and Ruby 2.5; the npm tools are used only for development and packaging.

## Build on Windows

Run `build.bat` from the repository (double-click it or run it from Command Prompt). It uses Windows PowerShell and creates `dist/variable_tools.rbz`; Node and npm are not needed to build. In SketchUp, open Extension Manager and choose Install Extension to install that RBZ.

## Development checks

To run the automated checks, install Node.js 18 or newer and Ruby (Ruby 2.5 is recommended for checking the oldest supported syntax), then run:

```sh
npm ci
npm test
```

On Windows, `npm test` runs the batch build and verifies the archive contents, then runs `ruby -c` on the extension's Ruby files. Ruby must be on `PATH`. The archive test is skipped on other platforms. Syntax checks do not exercise SketchUp's API or prove compatibility with older Ruby versions when run using a newer interpreter; manually test behavior in SketchUp as well. `npm run build` is also available on Windows and invokes the same batch file.
