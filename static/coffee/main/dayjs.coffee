# dayjs is vendored into static, esbuild does not pull it from node_modules
# See static/Tupfile

window.dayjs.extend window.dayjs_plugin_duration
window.dayjs.extend window.dayjs_plugin_calendar
window.dayjs.extend window.dayjs_plugin_advancedFormat

export default window.dayjs


