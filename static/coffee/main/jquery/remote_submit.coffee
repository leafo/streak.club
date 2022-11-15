export default $.fn.remote_submit = (selector, fn, validate_fn) ->
  click_input = null

  if $.isFunction selector
    validate_fn = fn
    fn = selector
    selector = undefined


  prefix = selector || ""
  @on "click", "#{prefix} button[name], #{prefix} input[type='submit'][name]", (e) =>
    btn = $(e.currentTarget)
    form = btn.closest("form")

    click_input?.remove()
    click_input = $("<input type='hidden' />")
      .attr("name", btn.attr "name")
      .val(btn.attr "value")
      .prependTo form

  submit_callback = (e, callback) =>
    e.preventDefault()
    form = $ e.currentTarget

    if validate_fn
      return unless validate_fn? form

    form.trigger "i:before_submit"

    buttons = form.addClass("loading")
      .find("button, input[type='submit']")
      .prop("disabled", true).addClass("disabled")

    $.post form.attr("action"), form.serializeArray(), (res) =>
      buttons.prop("disabled", false).removeClass "disabled"
      form.removeClass "loading"

      if callback?
        callback? res, form
      else
        fn res, form

    null

  if selector
    @on "submit", selector, submit_callback
  else
    @on "submit", submit_callback

