import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design/app_theme.dart';
import 'package:oasx/config/translation/i18n_content.dart';
import 'package:oasx/views/common/app_widgets.dart';

/// 脚本状态（与 lib/model/script_model.dart 的 ScriptState 保持一致）
enum BannerState { inactive, running, warning, updating }

/// 中间顶部的横幅：脚本名 + 调度器状态 + 控制按钮。
/// 背景由程序化渐变色块绘制，不引入外部游戏立绘资源。
class OverviewBanner extends StatelessWidget {
  const OverviewBanner({
    super.key,
    required this.title,
    required this.state,
    required this.onToggleScript,
    required this.onRunOnce,
    this.height = 148,
  });

  final String title;
  final BannerState state;
  final VoidCallback onToggleScript;
  final VoidCallback onRunOnce;
  final double height;

  @override
  Widget build(BuildContext context) {
    final running = state == BannerState.running;
    return AppPanel(
      padding: EdgeInsets.zero,
      clip: true,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _BannerBackdrop(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
                            // 亮色主题下用深色字，暗色主题下用冷白字
                            color: AppColors.panel.computeLuminance() < 0.5
                                ? const Color(0xFFEAF6FF)
                                : const Color(0xFF16303A),
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF3FB6E8).withValues(
                                  alpha: AppColors.panel.computeLuminance() < 0.5
                                      ? 0.8
                                      : 0.35,
                                ),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        I18n.scheduler.tr,
                        style: AppText.caption.copyWith(letterSpacing: 0.6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_subtitle(), style: AppText.caption),
                  const Spacer(),
                  Row(
                    children: [
                      _StateDot(state: state),
                      const SizedBox(width: 8),
                      AppChip(
                        label: _stateLabel(state),
                        background:
                            running ? AppColors.accentDark : AppColors.panelHi,
                        borderColor: running
                            ? AppColors.accent
                            : AppColors.borderStrong,
                        textColor: running
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        textStyle: const TextStyle(
                          fontSize: 9.5,
                          height: 1.2,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      _BannerButton(
                        icon: running
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        label: running ? 'STOP' : 'START',
                        active: running,
                        onTap: onToggleScript,
                      ),
                      const SizedBox(width: 6),
                      _BannerButton(
                        icon: Icons.playlist_play_rounded,
                        label: 'ONCE',
                        active: false,
                        onTap: onRunOnce,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle() => switch (state) {
        BannerState.running => I18n.running.tr,
        BannerState.inactive => I18n.no_task.tr,
        BannerState.warning => 'WARNING',
        BannerState.updating => 'SYNCING',
      };

  String _stateLabel(BannerState state) => switch (state) {
        BannerState.running => 'RUNNING',
        BannerState.inactive => 'IDLE',
        BannerState.warning => 'WARNING',
        BannerState.updating => 'SYNCING',
      };
}

class _BannerBackdrop extends StatelessWidget {
  const _BannerBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BackdropPainter(isDark: AppColors.panel.computeLuminance() < 0.5),
      child: const SizedBox.expand(),
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 底色：暗色用深海夜色，亮色用浅青灰，避免亮色主题里出现一块黑
    final baseColors = isDark
        ? const [Color(0xFF131A22), Color(0xFF0B0F14)]
        : const [Color(0xFFE8F2F6), Color(0xFFF2F7FA)];
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: baseColors,
        ).createShader(rect),
    );

    // 右侧青色光晕
    final glowCenter = Offset(size.width * 0.78, size.height * 0.32);
    final glowRadius = (size.width * 0.45).clamp(90.0, 320.0);
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF1F7A93).withValues(alpha: isDark ? 0.50 : 0.22),
            const Color(0xFF12414F).withValues(alpha: isDark ? 0.16 : 0.06),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(
            Rect.fromCircle(center: glowCenter, radius: glowRadius)),
    );

    // 左下暖色微光
    final warmCenter = Offset(size.width * 0.10, size.height * 1.08);
    final warmRadius = size.width * 0.32;
    canvas.drawCircle(
      warmCenter,
      warmRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF6B4A2A).withValues(alpha: isDark ? 0.30 : 0.12),
            Colors.transparent,
          ],
        ).createShader(
            Rect.fromCircle(center: warmCenter, radius: warmRadius)),
    );

    // 斜向细纹理
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.016)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width; x += 9) {
      canvas.drawLine(
          Offset(x, size.height), Offset(x + size.height, 0), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _StateDot extends StatelessWidget {
  const _StateDot({required this.state});
  final BannerState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      BannerState.running => AppColors.accent,
      BannerState.inactive => AppColors.textMuted,
      BannerState.warning => AppColors.warning,
      BannerState.updating => AppColors.info,
    };
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 7),
        ],
      ),
    );
  }
}

class _BannerButton extends StatefulWidget {
  const _BannerButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_BannerButton> createState() => _BannerButtonState();
}

class _BannerButtonState extends State<_BannerButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: active
                ? AppColors.accent
                : (_hover ? AppColors.panelHover : AppColors.panelHi),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: active ? AppColors.accent : AppColors.borderStrong,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 13,
                color:
                    active ? const Color(0xFF06231A) : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 9.5,
                  height: 1.1,
                  letterSpacing: 0.7,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? const Color(0xFF06231A)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
