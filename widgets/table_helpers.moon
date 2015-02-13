
class TableHelpers
  field_table: (object, fields, extra_fields) =>
    element "table", class: "nice_table field_table", ->
      for field in *fields
        local enum, custom_val

        if type(field) == "table"
          {field, enum} = field

        if type(enum) == "function"
          custom_val = enum
          enum = nil

        local style
        val = object[field]

        if enum
          val = "#{enum[val]} (#{val})"

        switch type(val)
          when "boolean"
            style = "color: #{val and "green" or "red"}"
          when "number"
            val = @format_number val
          when "nil"
            style = "color: gray; font-style: italic"

        if val and field\match "_at$"
          title = val
          val = time_ago_in_words val

        tr ->
          td -> strong field
          if custom_val
            td custom_val
          else
            td { :style, :title }, tostring val

      extra_fields! if extra_fields

