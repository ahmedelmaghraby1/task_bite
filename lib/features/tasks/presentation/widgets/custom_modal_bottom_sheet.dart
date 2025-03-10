import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskbite/core/constants/enums.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/core/localization/cubit/localization_cubit.dart';
import 'package:taskbite/core/themes/colors.dart';
import 'package:taskbite/core/utils/check_connection.dart';
import 'package:taskbite/core/utils/extensions.dart';
import 'package:taskbite/core/utils/permissions.dart';
import 'package:taskbite/features/home/presentation/widgets/head_title.dart';
import 'package:taskbite/features/tasks/data/models/task_model.dart';
import 'package:taskbite/features/tasks/presentation/widgets/add_task_button.dart';
import 'package:taskbite/features/tasks/presentation/widgets/add_task_text_field.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CustomModalBottomSheet extends StatefulWidget {
  final TaskModel? task;
  final dynamic taskKey;
  const CustomModalBottomSheet({super.key, this.task, this.taskKey});

  @override
  State<CustomModalBottomSheet> createState() => _CustomModalBottomSheetState();
}

class _CustomModalBottomSheetState extends State<CustomModalBottomSheet> {
  late bool titleEmpty;
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final FocusNode _titleFocusNode;
  late final FocusNode _contentFocusNode;
  late GlobalKey<FormState> _taskKey;
  late stt.SpeechToText _speech;
  late int _recordedTime = 0;
  late int minutes = 0;
  late int seconds = 0;
  bool _isListening = false;
  bool _micPermissionChecked = false;
  String _text = "";
  Timer? _timer;

  @override
  void initState() {
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();
    titleEmpty = widget.task == null ? true : false;
    _titleController =
        widget.task == null
            ? TextEditingController()
            : TextEditingController(text: widget.task!.title);
    _contentController =
        widget.task == null
            ? TextEditingController()
            : TextEditingController(text: widget.task!.content);
    _taskKey = GlobalKey<FormState>();
    _speech = stt.SpeechToText();

    super.initState();
  }

  void _startListening() async {
    final bool checkConnection = await hasInternetConnection();
    if (!checkConnection) {
      if (mounted) context.showSnack();
    } else {
      if (!_micPermissionChecked) {
        _micPermissionChecked = await checkMicPermission();
      } else {
        bool available = await _speech.initialize();
        if (available) {
          setState(() {
            _isListening = true;
          });
          _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
            setState(() {
              _recordedTime++;
              minutes = _recordedTime ~/ 60;
              seconds = _recordedTime % 60;
            });
          });
          _speech.listen(
            pauseFor: Duration(minutes: 5),
            localeId:
                mounted
                    ? LocalizationCubit.get(context).recordingLanguage
                    : 'ar',
            listenOptions: stt.SpeechListenOptions(
              partialResults: true,
              listenMode: stt.ListenMode.dictation,
              autoPunctuation: true,
            ),

            onResult: (result) {
              setState(() {
                _text += result.recognizedWords;
              });
            },
            onSoundLevelChange: (level) {
              if (level <= 0.1 && _isListening) {
                Future.delayed(const Duration(seconds: 3), () {
                  _stopListening();
                });
              }
            },
          );
        }
      }
    }
  }

  void _stopListening() {
    _recordedTime = 0;
    minutes = 0;
    seconds = 0;
    _speech.stop();
    _timer?.cancel();

    setState(() {
      _isListening = false;
      _contentController.text = _text;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _taskKey = GlobalKey<FormState>();
    _timer?.cancel();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: 600.h,
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 40.h),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 20.w),
                  child: HeadTitle(
                    title: (widget.task == null ? 'addTask' : 'editTask').tr(
                      context,
                    ),
                  ),
                ),
                SizedBox(height: 15.h),
                Form(
                  key: _taskKey,
                  child: Column(
                    children: [
                      AddTaskTextField(
                        maxLength: 30,
                        textEditingController: _titleController,
                        focusNode: _titleFocusNode,
                        onFieldSubmitted: (val) {
                          FocusScope.of(
                            context,
                          ).requestFocus(_contentFocusNode);
                        },
                        onTapOutside: (val) {
                          _titleFocusNode.unfocus();
                        },
                        textInputAction: TextInputAction.next,
                        text: 'taskTitle',
                        type: FieldType.normal,
                        onChanged: (value) {
                          setState(() {
                            if (_titleController.text.isNotEmpty ||
                                _titleController.text != '') {
                              titleEmpty = false;
                            } else {
                              titleEmpty = true;
                            }
                          });
                        },
                      ),
                      SizedBox(height: 20.h),
                      AddTaskTextField(
                        textEditingController: _contentController,
                        focusNode: _contentFocusNode,
                        onFieldSubmitted: (val) {
                          _contentFocusNode.unfocus();
                        },
                        onTapOutside: (val) {
                          _contentFocusNode.unfocus();
                        },
                        textInputAction: TextInputAction.done,
                        text: 'taskContent',
                        trailling: GestureDetector(
                          onTap: _isListening ? null : _startListening,

                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  _isListening ? Colors.red : AppColors.purpple,
                            ),
                            child: Icon(Icons.mic, color: AppColors.white),
                          ),
                        ),
                        type: FieldType.content,
                      ),
                    ],
                  ),
                ),
                Spacer(),

                SizedBox(height: 20.h),
                AddTaskButton(
                  task: widget.task,
                  taskKey: widget.taskKey,
                  type: widget.task == null ? ModalType.create : ModalType.edit,
                  titleEmpty: titleEmpty,
                  titleController: _titleController,
                  contentController: _contentController,
                  taskFormKey: _taskKey,
                ),
                SizedBox(height: 30.h),
              ],
            ),
            if (_isListening)
              PositionedDirectional(
                start: 15.w,
                end: 15.w,
                bottom: 150.h,
                child: GestureDetector(
                  onTap: _stopListening,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "stopRecording".tr(context),
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          "${'recording'.tr(context)}: ${minutes < 1 ? '' : '$minutes:'}$seconds",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
