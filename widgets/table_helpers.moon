
import time_ago_in_words from require "lapis.util"
import Enum from require "lapis.db.model"

class TableHelpers
  _extract_table_fields: (object) =>
    return for k, v in pairs object
      continue if type(v) == "table"
      if cls = object.__class
        plural = (k .. "s")\gsub("ss$", "ses")\gsub "ys$", "ies"
        enum = cls[plural]
        if enum and (enum.__class.__name == "Enum")
          k = {k, enum}
      k

  _format_table_value: (object, field) =>
    if type(field) == "string"
      field = {field}

    field_name = field[1]

    if type(field[2]) == "function"
      -- custom renderer
      return field_name, (-> field[2] object)

    value = if method_name = field_name\match "^:(.*)"
      method = object[method_name]
      unless method == nil
        assert type(method) == "function", "expected method for #{field}"
        method object
    else
      object[field_name]

    local opts, enum

    value_type = if value == nil
      "nil"
    elseif field.type
      field.type
    elseif type(field[2]) == "table" and field[2].__class == Enum
      enum = field[2]
      "enum"
    elseif field_name\match "_count$"
      "integer"
    elseif field_name\match("_at$") or field_name\match("_date_utc$")
      "date"
    else
      type value


    rendered_value, field_opts = switch value_type
      when "string"
        value
      when "integer", "number"
        if value == 0
          "0", { style: "color: gray" }
        else
          @number_format(value), {
            class: "integer_value"
          }
      when "nil"
        "nil", {
          class: "nil_value"
          style: "font-style: italic; color: gray"
        }
      when "boolean"
        "#{value}", {
          class: "bool_value"
          style: "color: #{value and "green" or "red"}"
        }
      when "date"
        @relative_timestamp(value), class: "date_value", title: value
      when "enum"
        assert enum, "tried to render field #{field_name} with no enum"
        if enum[value]
          enum\to_name(value), {
            title: value
            class: "enum_value"
            "data-name": field_name
            "data-value": enum\to_name(value)
          }
        else
          -> strong "Invalid enum value: #{value}"
      when "filesize"
        @filesize_format value
      when "checkbox"
        group_name = assert field.input, "missing input name for checkbox"
        form_name = assert field.form, "missing form for checkbox"

        ->
          label style: "margin: -10px; padding: 10px", ->
            input {
              type: "checkbox"
              class: field.class
              name: "#{group_name}[#{value}]"
              value: "on"
              form: form_name
            }
      else
        error "Don't know how to render type: #{value_type}"

    field_name, rendered_value, field_opts

  field_table: (object, fields, extra_fields) =>
    unless fields
      fields = @_extract_table_fields object

    element "table", class: "nice_table field_table", ->
      for field in *fields
        field, val, opts = @_format_table_value object, field

        tr ->
          td -> strong field
          td opts, val

      extra_fields! if extra_fields


  column_table: (objects, fields) =>
    element "table", class: "nice_table", ->
      thead ->
        tr ->
          for f in *fields
            if type(f) == "table"
              f = f.label or f[1]

            td f

      for object in *objects
        tr ->
          for field in *fields
            field, val, opts = @_format_table_value object, field
            td opts, val

