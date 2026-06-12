import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agora Video Call',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22D3EE),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AgoraCallPage(),
    );
  }
}

class AgoraCallPage extends StatefulWidget {
  const AgoraCallPage({super.key});

  @override
  State<AgoraCallPage> createState() => _AgoraCallPageState();
}

class _AgoraCallPageState extends State<AgoraCallPage> {
  final TextEditingController _appIdController = TextEditingController(text: '2a8687fe8d914abf92d572bc4fa97f50');
  final TextEditingController _channelController =
      TextEditingController(text: 'demo-channel');
  final TextEditingController _tokenController = TextEditingController();

  RtcEngine? _engine;
  RtcEngineEventHandler? _eventHandler;
  RtcConnection? _connection;
  int? _remoteUid;
  bool _isJoined = false;
  bool _isBusy = false;
  String _status = '2a8687fe8d914abf92d572bc4fa97f50';

  @override
  void dispose() {
    _cleanupEngine();
    _appIdController.dispose();
    _channelController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      await [Permission.camera, Permission.microphone].request();
    }
  }

  Future<void> _initializeEngine() async {
    final appId = _appIdController.text.trim();
    if (appId.isEmpty) {
      throw StateError('Agora App ID is required.');
    }

    await _requestPermissions();

    final engine = createAgoraRtcEngine();
    await engine.initialize(
      RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    final handler = RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isJoined = true;
          _connection = connection;
          _status = 'Joined ${connection.channelId} as ${connection.localUid}.';
        });
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        if (!mounted) {
          return;
        }
        setState(() {
          _connection = connection;
          _remoteUid = remoteUid;
          _status = 'Remote user $remoteUid joined.';
        });
      },
      onUserOffline: (connection, remoteUid, reason) {
        if (!mounted) {
          return;
        }
        setState(() {
          if (_remoteUid == remoteUid) {
            _remoteUid = null;
          }
          _status = 'Remote user $remoteUid left the channel.';
        });
      },
      onLeaveChannel: (connection, stats) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isJoined = false;
          _remoteUid = null;
          _connection = null;
          _status = 'Left the channel.';
        });
      },
      onError: (err, msg) {
        if (!mounted) {
          return;
        }
        setState(() {
          _status = 'Agora error $err: $msg';
        });
      },
    );

    engine.registerEventHandler(handler);
    await engine.enableVideo();
    await engine.startPreview();

    _engine = engine;
    _eventHandler = handler;
  }

  Future<void> _joinChannel() async {
    if (_isBusy) {
      return;
    }

    final channelId = _channelController.text.trim();
    if (channelId.isEmpty) {
      setState(() {
        _status = 'Channel name cannot be empty.';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _status = 'Preparing Agora engine...';
    });

    try {
      await _cleanupEngine(releaseOnly: true);
      await _initializeEngine();

      final token = _tokenController.text.trim();
      await _engine!.joinChannel(
        token: token,
        channelId: channelId,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          enableAudioRecordingOrPlayout: true,
        ),
      );
    } catch (error) {
      setState(() {
        _status = 'Failed to join channel: $error';
      });
      await _cleanupEngine(releaseOnly: true);
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _leaveChannel() async {
    if (_engine == null || _isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
      _status = 'Leaving channel...';
    });

    try {
      await _engine!.leaveChannel();
    } catch (error) {
      setState(() {
        _status = 'Failed to leave channel: $error';
      });
    } finally {
      await _cleanupEngine(releaseOnly: true);
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _cleanupEngine({bool releaseOnly = false}) async {
    final engine = _engine;
    final handler = _eventHandler;

    if (engine == null) {
      return;
    }

    try {
      if (handler != null) {
        engine.unregisterEventHandler(handler);
      }
    } catch (_) {}

    try {
      if (!releaseOnly) {
        await engine.leaveChannel();
      }
    } catch (_) {}

    try {
      await engine.release();
    } catch (_) {}

    _engine = null;
    _eventHandler = null;
    _connection = null;
    _remoteUid = null;
    _isJoined = false;
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0x1AFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildVideoTile({required Widget child, required String title}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF111827)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(child: child),
            Positioned(
              left: 16,
              top: 16,
              child: _PillLabel(text: title),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStage() {
    final engine = _engine;

    if (engine == null) {
      return _buildPlaceholderCard();
    }

    final localView = AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: engine,
        canvas: const VideoCanvas(uid: 0),
      ),
    );

    if (!_isJoined || _remoteUid == null || _connection == null) {
      return _buildVideoTile(
        title: 'Local Preview',
        child: localView,
      );
    }

    final remoteView = AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: engine,
        canvas: VideoCanvas(uid: _remoteUid!),
        connection: _connection!,
      ),
    );

    return Column(
      children: [
        SizedBox(
          height: 360,
          child: _buildVideoTile(
            title: 'Remote $_remoteUid',
            child: remoteView,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              width: 132,
              height: 176,
              child: _buildVideoTile(
                title: 'You',
                child: localView,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderCard() {
    return Container(
      height: 420,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF111827), Color(0xFF030712)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22D3EE).withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.videocam_rounded,
                size: 42,
                color: Color(0xFF67E8F9),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Video stage is ready',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter App ID and join a channel to start local preview.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final joined = _isJoined;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF111827)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Agora Video Call',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Minimal setup for live local preview and 1:1 call joining.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: const Color(0x0F0B1220),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 40,
                            color: Color(0x66000000),
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildInputField(
                            controller: _appIdController,
                            label: 'Agora App ID',
                            hint: 'Paste your Agora App ID here',
                          ),
                          const SizedBox(height: 12),
                          _buildInputField(
                            controller: _channelController,
                            label: 'Channel name',
                            hint: 'demo-channel',
                          ),
                          const SizedBox(height: 12),
                          _buildInputField(
                            controller: _tokenController,
                            label: 'Token (optional for now)',
                            hint: 'Leave blank if your project allows it',
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton.icon(
                                onPressed: _isBusy || joined ? null : _joinChannel,
                                icon: const Icon(Icons.call),
                                label: Text(_isBusy ? 'Working...' : 'Join call'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _isBusy || !joined ? null : _leaveChannel,
                                icon: const Icon(Icons.call_end),
                                label: const Text('Leave call'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _PillLabel(text: _status),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStage(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }
}