import dayjs from "dayjs"

import duration from "dayjs/plugin/duration"
import calendar from "dayjs/plugin/calendar"
import advancedFormat from "dayjs/plugin/advancedFormat"

dayjs.extend duration
dayjs.extend calendar
dayjs.extend advancedFormat

export default dayjs
