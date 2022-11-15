
argparse = require "argparse"

import types from require "tableshape"

import subclass_of from require "tableshape.moonscript"

parser = argparse "widget_helper.moon",
  "Widget compilinga and other tools"

parser\command_target "command"

with parser\command "debug"
  \argument "module_name"

with parser\command "compile_js", "Compile the individual js_init function for a module"
  \option("--module")
  \option("--file")
  \option("--package")

with parser\command "generate_spec", "Scan widgets and generate specification for compiling bundles"
  \option("--format", "Output format for scan results")\choices({"json", "tup"})\default "json"

args = parser\parse [v for _, v in ipairs _G.arg]

-- widgets/community/post_list.moon --> widgets.community.post_list
path_to_module = (path) ->
  (path\gsub("%.moon$", "")\gsub("/+", "."))

each_moon_file = do
  scan_prefix = (...) ->
    prefixes = {...}

    lfs = require "lfs"

    for prefix in *prefixes
      subdirs = {}

      for file in lfs.dir prefix
        continue if file == "."
        continue if file == ".."

        full_path = "#{prefix}/#{file}"
        attr = lfs.attributes full_path
        continue unless attr

        if attr.mode == "directory"
          table.insert subdirs, full_path
        else
          if full_path\match "%.moon$"
            coroutine.yield full_path

      scan_prefix unpack subdirs

  (...) ->
    prefixes = {...}
    coroutine.wrap -> scan_prefix unpack prefixes

each_widget = ->
  coroutine.wrap ->
    import Widget from require "lapis.html"
    is_widget = subclass_of Widget

    for file in each_moon_file "views", "widgets"
      module_name = path_to_module file
      widget = require module_name
      continue unless is_widget widget

      continue unless widget.asset_packages
      continue unless widget.compile_js_init
      continue unless rawget widget, "js_init"

      coroutine.yield {
        :file
        module_name: path_to_module file
        :widget
      }


switch args.command
  when "compile_js"
    if args.file
      widget = require path_to_module args.file
      print widget\compile_js_init!
    elseif args.module
      widget = require args.module
      print widget\compile_js_init!
    else
      count = 0

      for {:file, :widget} in each_widget!
        if args.package
          continue unless types.array_contains(args.package) widget.asset_packages

        js_code = assert widget\compile_js_init!
        count += 1
        print "// #{file} (#{table.concat widget.asset_packages, ", "})"
        print js_code

      if count == 0
        error "No package files (package: #{args.package})"

  when "generate_spec"
    import Widget from require "lapis.html"
    is_widget = subclass_of Widget

    import to_json from require "lapis.util"

    switch args.format
      when "json"
        asset_spec = {}

        for {:module_name, :widget} in each_widget!
          for package in *widget.asset_packages
            asset_spec[package] or= {}
            table.insert asset_spec[package], module_name

        print to_json asset_spec

      when "tup"
        -- 1. compile each module into js file, store in bucket
        -- 2. use that bucket as input to bundle

        package_files = {}

        for {:file, :module_name, :widget} in each_widget!
          for package in *widget.asset_packages
            package_files[package] or= {}
            table.insert package_files[package], file

        packages = [k for k in pairs package_files]
        table.sort packages

        print "# This file is automatically generated, do not edit"
        print "export LUA_PATH"
        print "export LUA_CPATH"

        for package in *packages
          files = package_files[package]
          print ": foreach #{table.concat files, " "} |> moon cmd/widget_helper.moon compile_js --file %f > %o |> %f.js {package_#{package}}"
          print ": {package_#{package}} |> cat %f > %o |> static/coffee/#{package}.js"
          print ": static/coffee/#{package}.js | $(TOP)/<coffee> |> NODE_PATH=static/coffee $(ESBUILD) --target=es6 --log-level=warning --bundle %f --outfile=%o |> static/#{package}.js"

  when "debug"
    require("moon").p args

    Widget = require args.module_name

    print "Config"
    print "=================="
    print "packages:", table.concat Widget.asset_packages, ", "
    print "init method:", Widget\js_init_method_name!

    print!

    print "Asset files"
    print "=================="
    print "scss:", Widget\get_asset_file "scss"
    print "coffee:", Widget\get_asset_file "coffee"

    print!

    print "JS Init"
    print "=================="
    print Widget\compile_js_init!

    -- print "Example invocation"
    -- print "=================="
    -- print Widget!\js_init { color: "blue" }



