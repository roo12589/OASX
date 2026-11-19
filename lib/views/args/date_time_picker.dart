// ignore_for_file: must_be_immutable

part of args;

/// 年份列表不能硬编码：写死到 2026 会导致 2026 年之后无法选择，
/// 也会让「置底一年后」这类操作选不到目标年份。
final List<String> dateYears = () {
  final nowYear = DateTime.now().year;
  // 往前 3 年（便于回填历史）、往后 10 年
  return List.generate(14, (i) => '${nowYear - 3 + i}');
}();
final dateMonths = List.generate(
        12, (index) => (index + 1) < 10 ? '0${index + 1}' : '${index + 1}')
    .toList();
final dateDaysInMonth = List.generate(31,
        (index) => (index + 1) < 10 ? '0${index + 1}' : '${index + 1}').toList();
final dateDaysInWeek =
    List.generate(7, (index) => index < 10 ? '0$index' : '$index').toList();
final dateHours =
    List.generate(24, (index) => index < 10 ? '0$index' : '$index').toList();
final dateMinutes =
    List.generate(60, (index) => index < 10 ? '0$index' : '$index').toList();
final dateSeconds =
    List.generate(60, (index) => index < 10 ? '0$index' : '$index').toList();

final dateTimeData = [
  dateYears,
  dateMonths,
  dateDaysInMonth,
  dateHours,
  dateMinutes,
  dateSeconds,
];
final dateTimeDelta = [
  dateDaysInWeek,
  dateHours,
  dateMinutes,
  dateSeconds,
];
final dateTime = [
  dateHours,
  dateMinutes,
  dateSeconds,
];

int daysInMonth() {
  DateTime now = DateTime.now();
  int year = now.year;
  int month = now.month;
  DateTime lastDayOfMonth =
      DateTime(year, month + 1, 1).subtract(const Duration(days: 1));
  return lastDayOfMonth.day;
}

String ensureTimeDeltaString(dynamic value) {
  if (value is String) {
    // 应该加上一个 格式的验证
    return value;
  } else if (value is int || value is double) {
    Duration duration = Duration(seconds: value.toInt());
    int day0 = duration.inDays;
    int hour0 = duration.inHours.remainder(24);
    int minute0 = duration.inMinutes.remainder(60);
    int second = duration.inSeconds.remainder(60);

    String day = day0 < 10 ? '0$day0' : '$day0';
    String hour = hour0 < 10 ? '0$hour0' : '$hour0';
    String minute = minute0 < 10 ? '0$minute0' : '$minute0';
    String seconds = second < 10 ? '0$second' : '$second';
    return '$day $hour:$minute:$seconds';
  }
  return '00 00:00:00';
}

// -------------------------------------------------------------------------Base

class DateTimePickerBase extends StatefulWidget {
  String value = '';
  void Function(String value) onChange = (value) {};

  DateTimePickerBase({super.key, required this.value, required this.onChange});

  @override
  State<StatefulWidget> createState() => DateTimePickerBaseState();
}

class DateTimePickerBaseState extends State<DateTimePickerBase> {
  // 鼠标是否在这个区域内
  bool _isHover = false;

  /// 控件左侧的图标，由子类按语义覆盖
  IconData get _icon => Icons.schedule_rounded;

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value.isNotEmpty;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (event) {
        setState(() {
          _isHover = true;
        });
      },
      onExit: (event) {
        setState(() {
          _isHover = false;
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          showPicker(context, widget.value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _isHover ? AppColors.panelHi : AppColors.panelSoft,
            borderRadius: AppRadius.chipR,
            border: Border.all(
              color: _isHover ? AppColors.borderStrong : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _icon,
                size: 14,
                color: _isHover ? AppColors.accent : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasValue ? widget.value : '--',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.mono.copyWith(
                    color: hasValue
                        ? (_isHover
                            ? AppColors.textPrimary
                            : AppColors.textSecondary)
                        : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.expand_more_rounded,
                size: 15,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 重写
  void showPicker(context, dynamic value) {
    Pickers.showMultiPicker(
      context,
      data: dateTimeData,
      suffix: [
        I18n.year.tr,
        I18n.month.tr,
        I18n.day.tr,
        I18n.hour.tr,
        I18n.minute.tr,
        I18n.seconds.tr
      ],
    );
  }
}

// ---------------------------------------------------------------------DateTime
class DateTimePicker extends DateTimePickerBase {
  DateTimePicker({super.key, required super.value, required super.onChange});

  @override
  State<StatefulWidget> createState() => DateTimePickerState();
}

class DateTimePickerState extends DateTimePickerBaseState {
  @override
  IconData get _icon => Icons.event_note_rounded;

  @override
  void showPicker(context, dynamic value) {
    Pickers.showMultiPicker(
      context,
      pickerStyle: Theme.of(context).brightness == Brightness.light
          ? DefaultPickerStyle()
          : DefaultPickerStyle.dark(),
      data: dateTimeData,
      selectData: prePrecess(value),
      onConfirm: onConfirm,
      suffix: [
        I18n.year.tr,
        I18n.month.tr,
        I18n.day.tr,
        I18n.hour.tr,
        I18n.minute.tr,
        I18n.seconds.tr
      ],
    );
  }

  dynamic onConfirm(List<dynamic> p, List<int> position) {
    String year = dateTimeData[0][position[0]];
    String month = dateTimeData[1][position[1]];
    String day = dateTimeData[2][position[2]];
    String hour = dateTimeData[3][position[3]];
    String minute = dateTimeData[4][position[4]];
    String seconds = dateTimeData[5][position[5]];
    widget.onChange('$year-$month-$day $hour:$minute:$seconds');
  }

  // 数据的预处理
  List prePrecess(dynamic value) {
    List result = [0, 0, 0, 0, 0, 0];
    // 如果是字符串, 那就分离出2023-10-02T11:11:11
    if (value is String) {
      result = value.split(RegExp(r'\D+'));
    }
    return result;
  }
}

// --------------------------------------------------------------------TimeDelta
class TimeDeltaPicker extends DateTimePickerBase {
  TimeDeltaPicker({super.key, required super.value, required super.onChange});

  @override
  State<StatefulWidget> createState() => TimeDeltaPickerState();
}

class TimeDeltaPickerState extends DateTimePickerBaseState {
  @override
  IconData get _icon => Icons.timelapse_rounded;

  @override
  void showPicker(context, dynamic value) {
    Pickers.showMultiPicker(
      context,
      pickerStyle: Theme.of(context).brightness == Brightness.light
          ? DefaultPickerStyle()
          : DefaultPickerStyle.dark(),
      data: dateTimeDelta,
      selectData: prePrecess(value),
      onConfirm: onConfirm,
      suffix: [I18n.day.tr, I18n.hour.tr, I18n.minute.tr, I18n.seconds.tr],
    );
  }

  dynamic onConfirm(List<dynamic> p, List<int> position) {
    String day = dateTimeDelta[0][position[0]];
    String hour = dateTimeDelta[1][position[1]];
    String minute = dateTimeDelta[2][position[2]];
    String seconds = dateTimeDelta[3][position[3]];
    widget.onChange('$day $hour:$minute:$seconds');
  }

  // 数据的预处理
  List prePrecess(dynamic value) {
    List result = [0, 0, 0, 0];
    // 如果是字符串, 那就分离出2023-10-02T11:11:11
    if (value is String) {
      result = value.split(RegExp(r'\D+'));
    }
    if (result is double) {
      Duration duration = Duration(seconds: value.toInt());
      String day = duration.inDays.toString();
      String hour = duration.inHours.toString();
      String minute = duration.inMinutes.toString();
      String seconds = duration.inSeconds.toString();
      result = [day, hour, minute, seconds];
    }
    return result;
  }
}

// -------------------------------------------------------------------------Time
class TimePicker extends DateTimePickerBase {
  TimePicker({super.key, required super.value, required super.onChange});

  @override
  State<StatefulWidget> createState() => TimePickerState();
}

class TimePickerState extends DateTimePickerBaseState {
  @override
  IconData get _icon => Icons.access_time_rounded;

  @override
  void showPicker(context, dynamic value) {
    Pickers.showMultiPicker(
      context,
      pickerStyle: Theme.of(context).brightness == Brightness.light
          ? DefaultPickerStyle()
          : DefaultPickerStyle.dark(),
      data: dateTime,
      selectData: prePrecess(value),
      onConfirm: onConfirm,
      suffix: [I18n.hour.tr, I18n.minute.tr, I18n.seconds.tr],
    );
  }

  dynamic onConfirm(List<dynamic> p, List<int> position) {
    String hour = dateTime[0][position[0]];
    String minute = dateTime[1][position[1]];
    String seconds = dateTime[2][position[2]];
    widget.onChange('$hour:$minute:$seconds');
  }

  // 数据的预处理
  List prePrecess(dynamic value) {
    List result = [0, 0, 0, 0];
    // 如果是字符串, 那就分离出2023-10-02T11:11:11
    if (value is String) {
      result = value.split(RegExp(r'\D+'));
    }
    return result;
  }
}
