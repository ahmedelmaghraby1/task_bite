import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taskbite/core/constants/enums.dart';
import 'package:taskbite/core/localization/app_localization.dart';
import 'package:taskbite/core/localization/cubit/localization_cubit.dart';
import 'package:taskbite/core/themes/colors.dart';
import 'package:taskbite/core/utils/alert_dialog.dart';
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
  bool titleEmpty = true;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  final GlobalKey<FormState> _taskKey = GlobalKey<FormState>();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool checkConnection = false;
  int _recordedTime = 0;
  int minutes = 0;
  int seconds = 0;
  bool _isListening = false;
  bool _micPermissionChecked = false;
  String _text = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _contentController.text = widget.task!.content;
      titleEmpty = false;
    }
  }

  @override
  void didChangeDependencies() async {
    checkConnection = await hasInternetConnection();
    super.didChangeDependencies();
  }

  void _startListening() async {
    if (!checkConnection) {
      if (mounted) context.showSnack();
      return;
    }

    _micPermissionChecked = await checkMicPermission();
    if (!_micPermissionChecked && mounted) {
      _handleMicPermissionDenied();
      return;
    }

    bool available = await _speech.initialize();
    if (available) {
      _startSpeechRecognition();
    }
  }

  void _handleMicPermissionDenied() async {
    _micPermissionChecked = await checkMicPermission();
    if (!_micPermissionChecked && mounted) {
      showAlertDialog(
        yesTitle: 'go',
        noTitle: 'back',
        onYesFunction: () {
          Navigator.pop(context);
          openAppSettings();
        },
        context,
        message: 'goToAppSettingsMessage'.tr(context),
      );
    }
  }

  void _startSpeechRecognition() {
    setState(() => _isListening = true);
    _startTimer();
    _speech.listen(
      pauseFor: Duration(minutes: 5),
      localeId:
          mounted ? LocalizationCubit.get(context).recordingLanguage : 'ar',
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        autoPunctuation: true,
      ),
      onResult: (result) {
        setState(() {
          _text = result.recognizedWords;
          if (result.finalResult) {
            _contentController.text = _text;
            _stopListening();
          }
        });
      },
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {
        _recordedTime++;
        minutes = _recordedTime ~/ 60;
        seconds = _recordedTime % 60;
      });
    });
  }

  void _stopListening() {
    if (!mounted) {
      return;
    } else {
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _timer?.cancel();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height:
          ((_titleFocusNode.hasFocus || _contentFocusNode.hasFocus) ? 650 : 550)
              .h,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
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
