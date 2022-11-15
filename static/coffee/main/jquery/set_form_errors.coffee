
$.fn.set_form_errors = (errors, scroll_to=true) ->
  @find(".form_errors").remove()

  if errors?.length
    errors_el = $ """
      <div class="form_errors">
        <div>Errors:</div>
        <ul></ul>
      </div>
    """

    errors_list = errors_el.find "ul"
    for e in errors
      errors_list.append $("<li></li>").text e

    @prepend errors_el

    if scroll_to
      @[0].scrollIntoView?()

  @

