import 'package:flutter/material.dart';
import '../models/printer.dart';

// ============ AFC LANE CARD ============
class AfcLaneCard extends StatefulWidget {
  final AFCLane lane;
  final bool isActive;
  final VoidCallback onLoad;
  final VoidCallback onUnload;
  final VoidCallback onTap;

  const AfcLaneCard({
    super.key,
    required this.lane,
    required this.isActive,
    required this.onLoad,
    required this.onUnload,
    required this.onTap,
  });

  @override
  State<AfcLaneCard> createState() => _AfcLaneCardState();
}

class _AfcLaneCardState extends State<AfcLaneCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AfcLaneCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.value = 0.3;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getStatusColor() {
    final status = widget.lane.status.toLowerCase();
    if (status == 'active' || status == 'loaded') return Colors.green;
    if (status == 'loading' || status == 'unloading') return Colors.orange;
    return Colors.grey;
  }

  String _getStatusText() {
    return widget.lane.status.toUpperCase();
  }

  bool _isLoading() {
    final status = widget.lane.status.toLowerCase();
    return status == 'loading' || status == 'unloading';
  }

  @override
  Widget build(BuildContext context) {
    final laneColor = widget.lane.color != null
        ? Color(int.parse("0xFF${widget.lane.color!.replaceAll('#', '')}"))
        : Colors.grey;
    final statusColor = _getStatusColor();
    final isLoading = _isLoading();
    final isEmpty = widget.lane.status.toLowerCase() == 'empty';

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            width: 110,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.isActive
                      ? statusColor
                          .withOpacity(0.15 + _glowAnimation.value * 0.1)
                      : Colors.white.withOpacity(0.03),
                  widget.isActive
                      ? statusColor.withOpacity(0.05)
                      : Colors.white.withOpacity(0.01),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isActive
                    ? statusColor.withOpacity(_glowAnimation.value)
                    : Colors.white.withOpacity(0.05),
                width: widget.isActive ? 2 : 1,
              ),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color:
                            statusColor.withOpacity(_glowAnimation.value * 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: laneColor,
                    shape: BoxShape.circle,
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: laneColor.withOpacity(0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: widget.isActive
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white54),
                              ),
                            )
                          : null,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.lane.name ?? "Lane ${widget.lane.id}",
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.lane.material ?? "—",
                  style: TextStyle(
                      fontSize: 10, color: Colors.white.withOpacity(0.5)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: statusColor),
                  ),
                ),
                const SizedBox(height: 8),
                _buildActionButton(statusColor, isLoading, isEmpty),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(Color statusColor, bool isLoading, bool isEmpty) {
    if (isLoading) {
      return SizedBox(
        width: double.infinity,
        child: Text(
          '...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5)),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEmpty ? widget.onLoad : widget.onUnload,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEmpty
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
          foregroundColor: isEmpty ? Colors.greenAccent : Colors.orangeAccent,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        child: Text(isEmpty ? 'LOAD' : 'UNLOAD'),
      ),
    );
  }
}

// ============ AFC STATUS BADGE ============
class AfcStatusBadge extends StatelessWidget {
  final String status;
  const AfcStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'ready':
      case 'idle':
        badgeColor = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case 'busy':
      case 'loading':
      case 'unloading':
        badgeColor = Colors.orange;
        icon = Icons.sync;
        break;
      case 'error':
        badgeColor = Colors.red;
        icon = Icons.error_outline;
        break;
      default:
        badgeColor = Colors.grey;
        icon = Icons.help_outline;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: badgeColor,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

// ============ AFC QUICK ACTION CHIP ============
class AfcActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const AfcActionChip(
      {super.key,
      required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ AFC QUICK ACTIONS PANEL ============
class AfcQuickActions extends StatelessWidget {
  final Function(String) onAction;
  const AfcQuickActions({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildActionGroup('MAIN', [
          AfcActionChip(
              label: 'Eject',
              icon: Icons.arrow_upward,
              color: Colors.orange,
              onTap: () => onAction('eject')),
          AfcActionChip(
              label: 'Cut',
              icon: Icons.content_cut,
              color: Colors.purple,
              onTap: () => onAction('cut')),
          AfcActionChip(
              label: 'Brush',
              icon: Icons.air,
              color: Colors.blue,
              onTap: () => onAction('brush')),
          AfcActionChip(
              label: 'Poop',
              icon: Icons.cleaning_services,
              color: Colors.teal,
              onTap: () => onAction('poop')),
          AfcActionChip(
              label: 'Park',
              icon: Icons.local_parking,
              color: Colors.amber,
              onTap: () => onAction('park')),
          AfcActionChip(
              label: 'Calibrate',
              icon: Icons.settings,
              color: Colors.cyan,
              onTap: () => onAction('calibration')),
        ]),
        const SizedBox(height: 12),
        _buildActionGroup('LED', [
          AfcActionChip(
              label: 'LED On',
              icon: Icons.lightbulb,
              color: Colors.green,
              onTap: () => onAction('led_on')),
          AfcActionChip(
              label: 'LED Off',
              icon: Icons.lightbulb_outline,
              color: Colors.grey,
              onTap: () => onAction('led_off')),
        ]),
        const SizedBox(height: 12),
        _buildActionGroup('SYSTEM', [
          AfcActionChip(
              label: 'Stats',
              icon: Icons.bar_chart,
              color: Colors.indigo,
              onTap: () => onAction('stats')),
          AfcActionChip(
              label: 'Quiet',
              icon: Icons.volume_off,
              color: Colors.blueGrey,
              onTap: () => onAction('quiet_mode')),
          AfcActionChip(
              label: 'Reset',
              icon: Icons.refresh,
              color: Colors.redAccent,
              onTap: () => onAction('reset_motor_time')),
        ]),
      ],
    );
  }

  Widget _buildActionGroup(String title, List<Widget> actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.3),
                letterSpacing: 1)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }
}
