import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineBanner extends StatefulWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> with SingleTickerProviderStateMixin {
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _sub;
  late AnimationController _controller;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnim = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (offline != _isOffline) {
        setState(() => _isOffline = offline);
        if (offline) {
          _controller.forward();
        } else {
          // Brief "back online" state, then slide out
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && !_isOffline) _controller.reverse();
          });
        }
      }
    });

    // Check initial state
    Connectivity().checkConnectivity().then((results) {
      if (mounted) {
        final offline = results.every((r) => r == ConnectivityResult.none);
        setState(() => _isOffline = offline);
        if (offline) _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            if (_controller.value == 0 && !_isOffline) return const SizedBox();
            return SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
              child: _isOffline ? _offlineBanner() : _onlineBanner(),
            );
          },
        ),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _offlineBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFB91C1C),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: const SafeArea(
        bottom: false,
        child: Row(children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'No internet connection — data may be outdated',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _onlineBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF059669),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: const SafeArea(
        bottom: false,
        child: Row(children: [
          Icon(Icons.wifi_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text('Back online', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
